const fs = require('fs');
const path = require('path');
const os = require('os');

class SecurityAudit {
  constructor() {
    this.logDir = process.env.AUDIT_LOG_PATH
      || path.join(
        process.env.LOCALAPPDATA
          || process.env.USERPROFILE
          || os.homedir(),
        'DaManage',
        'logs',
      );
    this.ensureLogDirectory();
  }

  ensureLogDirectory() {
    if (!fs.existsSync(this.logDir)) {
      fs.mkdirSync(this.logDir, { recursive: true });
    }
  }

  getLogFilePath(date = new Date()) {
    const dateStr = date.toISOString().slice(0, 10);
    return path.join(this.logDir, `security-${dateStr}.log`);
  }

  log(event, data = {}) {
    const entry = {
      timestamp: new Date().toISOString(),
      event,
      ...data,
    };

    try {
      fs.appendFileSync(this.getLogFilePath(), `${JSON.stringify(entry)}\n`, 'utf8');
    } catch (error) {
      console.error('Failed to write security audit log:', error.message);
    }
  }

  logSignup(username, ip, success = true, error = null) {
    this.log('SIGNUP', { username, ip, success, error });
  }

  logLogin(username, ip, success = true, error = null) {
    this.log('LOGIN', { username, ip, success, error });
  }

  logLogout(username, ip) {
    this.log('LOGOUT', { username, ip });
  }

  logFailedLogin(username, ip, reason) {
    this.log('FAILED_LOGIN', {
      username,
      ip,
      reason,
      severity: 'WARNING',
    });
  }

  logBruteForceDetected(identifier, ip, attemptsCount) {
    this.log('BRUTE_FORCE_DETECTED', {
      identifier,
      ip,
      attemptsCount,
      severity: 'CRITICAL',
    });
  }

  logRateLimitExceeded(ip, endpoint) {
    this.log('RATE_LIMIT_EXCEEDED', {
      ip,
      endpoint,
      severity: 'WARNING',
    });
  }

  logVaultAccess(userId, username, operation, success = true) {
    this.log('VAULT_ACCESS', {
      userId,
      username,
      operation,
      success,
    });
  }

  logSuspiciousActivity(description, data = {}) {
    this.log('SUSPICIOUS_ACTIVITY', {
      description,
      ...data,
      severity: 'CRITICAL',
    });
  }

  logTokenIssued(userId, username, expiresIn) {
    this.log('TOKEN_ISSUED', {
      userId,
      username,
      expiresIn,
    });
  }

  logTokenValidationFailed(reason, token = null) {
    this.log('TOKEN_VALIDATION_FAILED', {
      reason,
      tokenPrefix: token ? `${token.slice(0, 10)}...` : 'N/A',
      severity: 'WARNING',
    });
  }

  cleanupOldLogs(daysToKeep = 30) {
    try {
      const files = fs.readdirSync(this.logDir);
      const now = Date.now();
      const maxAge = daysToKeep * 24 * 60 * 60 * 1000;

      files
        .filter((file) => file.startsWith('security-') && file.endsWith('.log'))
        .forEach((file) => {
          const filePath = path.join(this.logDir, file);
          const stats = fs.statSync(filePath);
          const age = now - stats.mtimeMs;

          if (age > maxAge) {
            fs.unlinkSync(filePath);
            console.log(`Deleted old security log: ${file}`);
          }
        });
    } catch (error) {
      console.error('Failed to cleanup old logs:', error.message);
    }
  }
}

module.exports = new SecurityAudit();
