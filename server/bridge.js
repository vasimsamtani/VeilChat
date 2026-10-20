/**
 * VeilChat Local WhatsApp Multi-Device Bridge
 * Protocol: Noise Protocol Framework over WebSockets (@whiskeysockets/baileys)
 * Port: 5055 (WebSocket IPC with VeilChat Flutter client)
 */

const {
  default: makeWASocket,
  useMultiFileAuthState,
  DisconnectReason,
  fetchLatestBaileysVersion,
  makeCacheableSignalKeyStore,
} = require('@whiskeysockets/baileys');
const pino = require('pino');
const { WebSocketServer } = require('ws');
const http = require('http');
const qrcodeTerminal = require('qrcode-terminal');
const path = require('path');
const fs = require('fs');
const os = require('os');

function getLocalIp() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return '127.0.0.1';
}

const PORT = process.env.PORT || 5055;
const AUTH_DIR = path.join(__dirname, 'auth_info_baileys');
const CHATS_FILE = path.join(__dirname, 'chats_store.json');

// Ensure auth dir exists
if (!fs.existsSync(AUTH_DIR)) {
  fs.mkdirSync(AUTH_DIR, { recursive: true });
}

const logger = pino({ level: 'warn' });

let sock = null;
let currentQR = null;
let connectionStatus = 'disconnected'; // 'disconnected' | 'connecting' | 'qr_ready' | 'connected'
let activeUser = null;
const connectedClients = new Set();
const chatCache = new Map();

// Load persistent chats from disk
if (fs.existsSync(CHATS_FILE)) {
  try {
    const raw = JSON.parse(fs.readFileSync(CHATS_FILE, 'utf-8'));
    for (const chat of raw) {
      if (chat && chat.id) chatCache.set(chat.id, chat);
    }
    console.log(`[Bridge] Loaded ${chatCache.size} persistent chats from disk.`);
  } catch (err) {
    console.error('[Bridge] Error loading persistent chats:', err.message);
  }
}

function saveChatsToDisk() {
  try {
    fs.writeFileSync(CHATS_FILE, JSON.stringify(Array.from(chatCache.values()), null, 2));
  } catch (err) {
    console.error('[Bridge] Error saving persistent chats:', err.message);
  }
}

// Helper to broadcast JSON events to all connected VeilChat Flutter clients
function broadcast(payload) {
  const json = JSON.stringify(payload);
  for (const client of connectedClients) {
    if (client.readyState === 1 /* OPEN */) {
      try {
        client.send(json);
      } catch (err) {
        console.error('[Bridge] Error broadcasting to client:', err.message);
      }
    }
  }
}

// Extract human-readable text from various WhatsApp message types (including view-once and ephemeral)
function extractMessageText(msg) {
  if (!msg.message) return '';
  let m = msg.message;
  while (
    m?.ephemeralMessage?.message ||
    m?.viewOnceMessage?.message ||
    m?.viewOnceMessageV2?.message ||
    m?.viewOnceMessageV2Extension?.message ||
    m?.documentWithCaptionMessage?.message
  ) {
    m = (
      m.ephemeralMessage ||
      m.viewOnceMessage ||
      m.viewOnceMessageV2 ||
      m.viewOnceMessageV2Extension ||
      m.documentWithCaptionMessage
    ).message;
  }
  return (
    m?.conversation ||
    m?.extendedTextMessage?.text ||
    m?.imageMessage?.caption ||
    m?.videoMessage?.caption ||
    m?.documentMessage?.caption ||
    m?.buttonsResponseMessage?.selectedButtonId ||
    m?.listResponseMessage?.singleSelectReply?.selectedRowId ||
    m?.templateButtonReplyMessage?.selectedId ||
    (m?.imageMessage ? '📷 Photo' : '') ||
    (m?.videoMessage ? '📹 Video' : '') ||
    (m?.audioMessage ? '🎵 Voice note' : '') ||
    (m?.documentMessage ? '📄 Document' : '') ||
    (m?.stickerMessage ? '🎨 Sticker' : '') ||
    ''
  );
}

// Format message for VeilChat
function formatMessageForVeilChat(msg) {
  const text = extractMessageText(msg);
  const isFromMe = Boolean(msg.key.fromMe);
  const remoteJid = msg.key.remoteJid;
  const timestampMs = (msg.messageTimestamp ? Number(msg.messageTimestamp) : Math.floor(Date.now() / 1000)) * 1000;
  
  // Format readable time (e.g. 10:42 AM)
  const d = new Date(timestampMs);
  const timeStr = d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

  return {
    id: msg.key.id,
    remoteJid: remoteJid,
    senderName: msg.pushName || (isFromMe ? 'You' : remoteJid.split('@')[0]),
    text: text,
    timestamp: timestampMs,
    timeStr: timeStr,
    isFromMe: isFromMe,
    status: msg.status || 'delivered',
    hasMedia: Boolean(
      msg.message?.imageMessage ||
      msg.message?.videoMessage ||
      msg.message?.audioMessage ||
      msg.message?.documentMessage
    ),
    mediaType: msg.message?.imageMessage
      ? 'image'
      : msg.message?.videoMessage
      ? 'video'
      : msg.message?.audioMessage
      ? 'audio'
      : null,
  };
}

async function startWhatsAppSocket() {
  console.log('[Bridge] Initializing WhatsApp Multi-Device session...');
  connectionStatus = 'connecting';
  broadcast({ type: 'status', status: connectionStatus });

  const { state, saveCreds } = await useMultiFileAuthState(AUTH_DIR);
  const { version, isLatest } = await fetchLatestBaileysVersion();
  console.log(`[Bridge] Using WA v${version.join('.')}, isLatest: ${isLatest}`);

  sock = makeWASocket({
    version,
    logger,
    printQRInTerminal: false,
    auth: {
      creds: state.creds,
      keys: makeCacheableSignalKeyStore(state.keys, logger),
    },
    generateHighQualityLinkPreview: true,
    browser: ['VeilChat Security Suite', 'Chrome', '1.0.0'],
    syncFullHistory: true,
    connectTimeoutMs: 60000,
    defaultQueryTimeoutMs: 90000,
    keepAliveIntervalMs: 25000,
  });

  // Contact names cache
  const contactCache = new Map();

  // Save auth state updates
  sock.ev.on('creds.update', saveCreds);

  // Connection events (QR, open, close)
  sock.ev.on('connection.update', (update) => {
    const { connection, lastDisconnect, qr } = update;

    if (qr) {
      currentQR = qr;
      connectionStatus = 'qr_ready';
      console.log('\n=============================================================');
      console.log('[Bridge] Scan this QR code in WhatsApp (Linked Devices):');
      console.log('=============================================================');
      qrcodeTerminal.generate(qr, { small: true });
      console.log('=============================================================\n');

      broadcast({
        type: 'qr',
        qr: qr,
        status: connectionStatus,
      });
    }

    if (connection === 'open') {
      currentQR = null;
      connectionStatus = 'connected';
      activeUser = sock.user;
      console.log(`[Bridge] WhatsApp connected successfully! Linked as: ${activeUser?.id || activeUser?.name}`);

      broadcast({
        type: 'connected',
        status: connectionStatus,
        user: activeUser,
        chats: Array.from(chatCache.values()),
      });
    }

    if (connection === 'close') {
      const statusCode = lastDisconnect?.error?.output?.statusCode;
      const shouldReconnect = statusCode !== DisconnectReason.loggedOut;
      console.log(`[Bridge] Connection closed with status code ${statusCode}. Reconnecting: ${shouldReconnect}`);

      connectionStatus = 'disconnected';
      activeUser = null;
      broadcast({
        type: 'status',
        status: connectionStatus,
        error: lastDisconnect?.error?.message,
      });

      if (shouldReconnect) {
        setTimeout(startWhatsAppSocket, 3000);
      } else {
        console.log('[Bridge] Session logged out. Clearing auth credentials...');
        try {
          fs.rmSync(AUTH_DIR, { recursive: true, force: true });
        } catch (e) {
          console.error('[Bridge] Error clearing auth dir:', e.message);
        }
        setTimeout(startWhatsAppSocket, 2000);
      }
    }
  });

  // Track contacts & populate chat list
  sock.ev.on('contacts.upsert', (newContacts) => {
    let updated = false;
    for (const c of newContacts) {
      if (c.id && !c.id.includes('@lid') && c.id !== 'status@broadcast') {
        const name = c.name || c.notify || c.verifiedName;
        if (name) {
          contactCache.set(c.id, name);
          if (!chatCache.has(c.id)) {
            chatCache.set(c.id, {
              id: c.id,
              name: name,
              unreadCount: 0,
              conversationTimestamp: Math.floor(Date.now() / 1000),
              lastMessageText: '',
              lastMessageTime: '',
            });
            updated = true;
          } else {
            chatCache.get(c.id).name = name;
            updated = true;
          }
        }
      }
    }
    if (updated) {
      saveChatsToDisk();
      broadcast({ type: 'chats_update', chats: Array.from(chatCache.values()) });
    }
  });

  sock.ev.on('contacts.set', ({ contacts }) => {
    let updated = false;
    for (const c of contacts) {
      if (c.id && !c.id.includes('@lid') && c.id !== 'status@broadcast') {
        const name = c.name || c.notify || c.verifiedName;
        if (name) {
          contactCache.set(c.id, name);
          if (!chatCache.has(c.id)) {
            chatCache.set(c.id, {
              id: c.id,
              name: name,
              unreadCount: 0,
              conversationTimestamp: Math.floor(Date.now() / 1000),
              lastMessageText: '',
              lastMessageTime: '',
            });
            updated = true;
          } else {
            chatCache.get(c.id).name = name;
            updated = true;
          }
        }
      }
    }
    if (updated) {
      saveChatsToDisk();
      broadcast({ type: 'chats_update', chats: Array.from(chatCache.values()) });
    }
  });

  // WhatsApp Multi-Device History Sync (Real Chats & Messages)
  sock.ev.on('messaging-history.set', ({ chats, contacts, messages, isLatest }) => {
    console.log(`[Bridge] History sync received: ${chats?.length || 0} chats, ${messages?.length || 0} messages`);
    
    if (contacts) {
      for (const c of contacts) {
        if (c.id) {
          const name = c.name || c.notify || c.verifiedName;
          if (name) contactCache.set(c.id, name);
        }
      }
    }

    if (chats) {
      for (const chat of chats) {
        if (!chat.id || chat.id === 'status@broadcast') continue;
        const contactName = contactCache.get(chat.id);
        const name = chat.name || contactName || chat.id.split('@')[0];
        chatCache.set(chat.id, {
          id: chat.id,
          name: name,
          unreadCount: chat.unreadCount || 0,
          conversationTimestamp: chat.conversationTimestamp || Math.floor(Date.now() / 1000),
          lastMessageText: '',
          lastMessageTime: '',
        });
      }
    }

    if (messages) {
      for (const m of messages) {
        if (!m.message) continue;
        const formatted = formatMessageForVeilChat(m);
        if (formatted.remoteJid && chatCache.has(formatted.remoteJid)) {
          const c = chatCache.get(formatted.remoteJid);
          const msgTimestamp = Math.floor(formatted.timestamp / 1000);
          if (!c.lastMessageText || (c.conversationTimestamp || 0) <= msgTimestamp) {
            c.lastMessageText = formatted.text;
            c.lastMessageTime = formatted.timeStr;
            c.conversationTimestamp = msgTimestamp;
          }
        }
      }
    }

    broadcast({ type: 'chats_update', chats: Array.from(chatCache.values()) });
  });

  // Sync chats
  sock.ev.on('chats.set', ({ chats }) => {
    for (const chat of chats) {
      if (!chat.id || chat.id === 'status@broadcast') continue;
      const contactName = contactCache.get(chat.id);
      chatCache.set(chat.id, {
        id: chat.id,
        name: chat.name || contactName || chat.id.split('@')[0],
        unreadCount: chat.unreadCount || 0,
        conversationTimestamp: chat.conversationTimestamp,
      });
    }
    broadcast({ type: 'chats_update', chats: Array.from(chatCache.values()) });
  });

  sock.ev.on('chats.upsert', (newChats) => {
    for (const chat of newChats) {
      if (!chat.id || chat.id === 'status@broadcast') continue;
      const existing = chatCache.get(chat.id) || {};
      const contactName = contactCache.get(chat.id);
      chatCache.set(chat.id, {
        ...existing,
        ...chat,
        name: chat.name || existing.name || contactName || chat.id.split('@')[0],
      });
    }
    broadcast({ type: 'chats_update', chats: Array.from(chatCache.values()) });
  });

  // Incoming live messages
  sock.ev.on('messages.upsert', async ({ messages, type }) => {
    for (const m of messages) {
      if (!m.message) continue;
      const remoteJid = m.key.remoteJid;
      if (!remoteJid || remoteJid === 'status@broadcast' || remoteJid.endsWith('@lid')) {
        continue;
      }

      const formatted = formatMessageForVeilChat(m);
      if (!formatted.text && !formatted.hasMedia) {
        continue;
      }

      const contactName = contactCache.get(remoteJid);
      const displayName = formatted.senderName || contactName || remoteJid.split('@')[0];
      
      let c = chatCache.get(remoteJid);
      if (!c) {
        c = {
          id: remoteJid,
          name: displayName,
          unreadCount: 0,
        };
        chatCache.set(remoteJid, c);
      }
      c.lastMessageText = formatted.text || (formatted.hasMedia ? `[${formatted.mediaType}]` : '');
      c.lastMessageTime = formatted.timeStr;
      c.conversationTimestamp = Math.floor(formatted.timestamp / 1000);
      if (!formatted.isFromMe) {
        c.unreadCount = (c.unreadCount || 0) + 1;
      }

      saveChatsToDisk();

      console.log(`[Bridge] New message in ${remoteJid} from ${formatted.senderName}: "${formatted.text}"`);

      broadcast({
        type: 'message_new',
        message: formatted,
      });

      broadcast({ type: 'chats_update', chats: Array.from(chatCache.values()) });
    }
  });
}

// -------------------------------------------------------------
// HTTP & WebSocket Server for Cloud & Local Clients
// -------------------------------------------------------------
const server = http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    return res.end();
  }

  // Health check endpoint for cloud platforms (Render, Railway, Fly.io)
  if (req.url === '/health' || req.url === '/') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    return res.end(
      JSON.stringify({
        status: connectionStatus,
        service: 'VeilChat WhatsApp Cloud Bridge',
        user: activeUser ? activeUser.id : null,
        chatsCount: chatCache.size,
      })
    );
  }

  // Web QR page: Scan directly from any browser or phone
  if (req.url === '/qr') {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    if (connectionStatus === 'connected') {
      return res.end(`
        <!DOCTYPE html>
        <html>
        <head><title>VeilChat Bridge - Connected</title><meta name="viewport" content="width=device-width,initial-scale=1"></head>
        <body style="background:#0d1117;color:#3fb950;font-family:sans-serif;display:flex;flex-direction:column;align-items:center;justify-content:center;height:100vh;margin:0;">
          <h1 style="margin:0 0 10px 0;">WhatsApp Connected!</h1>
          <p style="color:#8b949e;">Linked as: ${activeUser?.id || 'Active User'}</p>
        </body>
        </html>
      `);
    }

    if (currentQR) {
      return res.end(`
        <!DOCTYPE html>
        <html>
        <head><title>VeilChat WhatsApp QR</title><meta name="viewport" content="width=device-width,initial-scale=1"></head>
        <body style="background:#0d1117;color:white;font-family:sans-serif;display:flex;flex-direction:column;align-items:center;justify-content:center;height:100vh;margin:0;">
          <h2 style="margin-bottom:16px;">Scan with WhatsApp (Linked Devices)</h2>
          <div style="background:white;padding:16px;border-radius:16px;box-shadow:0 8px 30px rgba(0,0,0,0.5);">
            <img src="https://api.qrserver.com/v1/create-qr-code/?size=280x280&data=${encodeURIComponent(currentQR)}" width="280" height="280" />
          </div>
          <p style="color:#8b949e;margin-top:20px;font-size:14px;">Keep this tab open. Auto-refresh if QR expires.</p>
          <script>setTimeout(() => location.reload(), 20000);</script>
        </body>
        </html>
      `);
    }

    return res.end(`
      <!DOCTYPE html>
      <html>
      <head><title>VeilChat Bridge</title><meta name="viewport" content="width=device-width,initial-scale=1"></head>
      <body style="background:#0d1117;color:#8b949e;font-family:sans-serif;display:flex;flex-direction:column;align-items:center;justify-content:center;height:100vh;margin:0;">
        <h2>Generating QR code...</h2>
        <p>Please refresh in 5 seconds.</p>
        <script>setTimeout(() => location.reload(), 5000);</script>
      </body>
      </html>
    `);
  }

  res.writeHead(404);
  res.end('Not Found');
});

const wss = new WebSocketServer({ server });

wss.on('connection', (ws) => {
  connectedClients.add(ws);
  console.log(`[Bridge] VeilChat Flutter client connected (Total clients: ${connectedClients.size})`);

  // Send current status immediately upon connection
  ws.send(
    JSON.stringify({
      type: 'status',
      status: connectionStatus,
      qr: currentQR,
      user: activeUser,
      chats: Array.from(chatCache.values()),
    })
  );

  ws.on('message', async (data) => {
    try {
      const msg = JSON.parse(data.toString());
      console.log('[Bridge] Client request:', msg.action || msg.type);

      switch (msg.action) {
        case 'get_status':
          ws.send(
            JSON.stringify({
              type: 'status',
              status: connectionStatus,
              qr: currentQR,
              user: activeUser,
              chats: Array.from(chatCache.values()),
            })
          );
          break;

        case 'start_chat':
          let startJid = msg.jid;
          if (!startJid.includes('@')) {
            startJid = `${startJid}@s.whatsapp.net`;
          }
          let existingChat = chatCache.get(startJid);
          if (!existingChat) {
            existingChat = {
              id: startJid,
              name: msg.name || startJid.split('@')[0],
              unreadCount: 0,
              conversationTimestamp: Math.floor(Date.now() / 1000),
              lastMessageText: '',
              lastMessageTime: 'Just now',
            };
            chatCache.set(startJid, existingChat);
            saveChatsToDisk();
          }
          broadcast({ type: 'chats_update', chats: Array.from(chatCache.values()) });
          break;

        case 'send_message':
          if (!sock || connectionStatus !== 'connected') {
            ws.send(
              JSON.stringify({
                type: 'error',
                action: 'send_message',
                message: 'WhatsApp is not connected',
              })
            );
            return;
          }

          if (!msg.jid || !msg.text) {
            ws.send(
              JSON.stringify({
                type: 'error',
                action: 'send_message',
                message: 'Missing jid or text',
              })
            );
            return;
          }

          // Format JID if it's just a phone number
          let targetJid = msg.jid;
          if (!targetJid.includes('@')) {
            targetJid = `${targetJid}@s.whatsapp.net`;
          }

          console.log(`[Bridge] Sending message to ${targetJid}: "${msg.text}"`);
          const sent = await sock.sendMessage(targetJid, { text: msg.text });

          // Update local chat cache and persist
          let targetChat = chatCache.get(targetJid);
          const d = new Date();
          const timeStr = d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
          if (!targetChat) {
            targetChat = {
              id: targetJid,
              name: targetJid.split('@')[0],
              unreadCount: 0,
            };
            chatCache.set(targetJid, targetChat);
          }
          targetChat.lastMessageText = msg.text;
          targetChat.lastMessageTime = timeStr;
          targetChat.conversationTimestamp = Math.floor(Date.now() / 1000);
          saveChatsToDisk();

          broadcast({ type: 'chats_update', chats: Array.from(chatCache.values()) });

          ws.send(
            JSON.stringify({
              type: 'message_sent',
              id: sent.key.id,
              jid: targetJid,
              text: msg.text,
              timestamp: Date.now(),
            })
          );
          break;

        case 'logout':
          if (sock) {
            console.log('[Bridge] Disconnecting and logging out WhatsApp...');
            await sock.logout();
          }
          break;

        case 'restart_bridge':
          if (sock) {
            try {
              sock.end();
            } catch (_) {}
          }
          startWhatsAppSocket();
          break;

        default:
          console.warn('[Bridge] Unknown action:', msg.action);
      }
    } catch (err) {
      console.error('[Bridge] Error handling message:', err.message);
      ws.send(JSON.stringify({ type: 'error', message: err.message }));
    }
  });

  ws.on('close', () => {
    connectedClients.delete(ws);
    console.log(`[Bridge] VeilChat Flutter client disconnected (Remaining: ${connectedClients.size})`);
  });
});

server.listen(PORT, '0.0.0.0', () => {
  const localIp = getLocalIp();
  console.log(`\n=============================================================`);
  console.log(` VeilChat WhatsApp Bridge is ONLINE`);
  console.log(` Local PC WebSocket: ws://127.0.0.1:${PORT}`);
  console.log(` Android Phone WebSocket: ws://${localIp}:${PORT}`);
  console.log(` Web QR code: http://${localIp}:${PORT}/qr`);
  console.log(`=============================================================\n`);
});

// Start WhatsApp socket
startWhatsAppSocket().catch((err) => {
  console.error('[Bridge] Failed to start WhatsApp socket:', err);
});
