/**
 * Service Discovery via Bonjour/mDNS
 * 
 * Uses macOS native dns-sd command for zero-dependency Bonjour
 * iOS can discover using NetServiceBrowser
 */

import { spawn } from 'child_process';
import os from 'os';
import { logger } from './utils/logger.js';

let dnssdProcess = null;

/**
 * Advertise service via Bonjour
 * Service type: _termlinky._tcp
 */
export function startDiscovery(port, serverInfo) {
  const serviceType = '_termlinky._tcp';
  const serviceName = serverInfo.hostname || os.hostname();
  
  // TXT record data (key=value pairs for service metadata)
  const txtRecords = [
    `version=${serverInfo.version || '1.0.0'}`,
    `hostname=${serviceName}`,
    `tailscale=${serverInfo.tailscaleIP}`,
    `claude=${serverInfo.claudeEnabled ? 'true' : 'false'}`,
    `shell=${serverInfo.shell || '/bin/zsh'}`,
  ];
  
  // Build dns-sd command
  // dns-sd -R <name> <type> <domain> <port> [txt records...]
  const args = [
    '-R',                    // Register service
    serviceName,             // Service name
    serviceType,             // Service type
    'local',                 // Domain
    port.toString(),         // Port
    ...txtRecords            // TXT records
  ];
  
  logger.info(`Starting Bonjour discovery: ${serviceName} on ${serviceType}`);
  logger.info(`TXT records: ${txtRecords.join(', ')}`);
  
  try {
    dnssdProcess = spawn('dns-sd', args, {
      stdio: ['ignore', 'pipe', 'pipe'],
      detached: false
    });
    
    dnssdProcess.stdout.on('data', (data) => {
      const output = data.toString().trim();
      if (output.includes('Registered')) {
        logger.info(`📡 Bonjour: ${output}`);
      }
    });
    
    dnssdProcess.stderr.on('data', (data) => {
      logger.warn(`Bonjour stderr: ${data.toString().trim()}`);
    });
    
    dnssdProcess.on('error', (err) => {
      logger.error(`Bonjour error: ${err.message}`);
    });
    
    dnssdProcess.on('exit', (code, signal) => {
      if (code !== null && code !== 0) {
        logger.warn(`Bonjour exited with code ${code}`);
      }
      dnssdProcess = null;
    });
    
    logger.info('📡 Bonjour discovery started');
    return true;
    
  } catch (err) {
    logger.error(`Failed to start Bonjour: ${err.message}`);
    return false;
  }
}

/**
 * Stop Bonjour advertisement
 */
export function stopDiscovery() {
  if (dnssdProcess) {
    logger.info('Stopping Bonjour discovery');
    dnssdProcess.kill();
    dnssdProcess = null;
  }
}

/**
 * Get discovery info for manual configuration
 */
export function getDiscoveryInfo(port, tailscaleIP) {
  return {
    serviceType: '_termlinky._tcp',
    port,
    tailscaleIP,
    hostname: os.hostname(),
    wsUrl: `ws://${tailscaleIP}:${port}/terminal`,
    httpUrl: `http://${tailscaleIP}:${port}`,
    manualSetup: {
      host: tailscaleIP,
      port: port
    }
  };
}
