import { useEffect } from 'react';
import { Shield, Lock, FileCode, AlertTriangle, ExternalLink } from 'lucide-react';
import { RELEASE_INFO } from '../constants/releaseInfo';

export const SecurityPage = () => {
  useEffect(() => {
    window.scrollTo(0, 0);
  }, []);

  return (
    <div className="py-16 sm:py-24 bg-[#0D1420] text-slate-300">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="mb-12 border-b border-slate-800 pb-8">
          <div className="inline-flex items-center gap-2 px-3.5 py-1 rounded-full bg-[#3978F6]/15 border border-[#3978F6]/30 text-[#3978F6] text-xs font-bold uppercase tracking-wider mb-4">
            <Shield className="w-4 h-4" />
            Security & Threat Model
          </div>
          <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight">
            Security Policy & Architecture
          </h1>
          <p className="mt-3 text-sm font-mono text-[#39C6B0]">
            DEFENSE IN DEPTH • VERIFIED INTEGRITY • STRIDE MODEL
          </p>
        </div>

        <div className="space-y-10 leading-relaxed text-sm sm:text-base">
          <section className="space-y-3">
            <h2 className="text-2xl font-bold text-white flex items-center gap-2">
              <Lock className="w-5 h-5 text-[#3978F6]" />
              Cryptographic Primitives & Identity
            </h2>
            <p>
              NEXORA employs audited cryptographic primitives for identity and file integrity:
            </p>
            <ul className="list-disc pl-6 space-y-2 text-slate-300">
              <li><strong>Ed25519 Keypairs:</strong> Devices generate an asymmetric Ed25519 keypair for cryptographic identity and ephemeral challenge-response signing.</li>
              <li><strong>SHA-256 Streaming Integrity:</strong> Every 1MB chunk and whole-file manifest is verified via standard SHA-256 hash digests. Corrupted or tampered chunks are immediately discarded.</li>
              <li><strong>6-Digit SAS Code:</strong> During pairing, an out-of-band 6-digit Short Authentication String (SAS) enables users to visually verify that no man-in-the-middle is intercepting the key exchange.</li>
            </ul>
          </section>

          <section className="space-y-3">
            <h2 className="text-2xl font-bold text-white flex items-center gap-2">
              <FileCode className="w-5 h-5 text-[#39C6B0]" />
              Wire Frame Ceiling (Memory Exhaustion Defense)
            </h2>
            <p>
              To protect against remote Denial-of-Service and memory allocation attacks, the framed socket reader reads a 4-byte big-endian length prefix and enforces a strict <strong>5 MB hard ceiling</strong>:
            </p>
            <div className="p-4 bg-[#14243B]/60 rounded-xl border border-slate-800 font-mono text-xs text-slate-300">
              if frame_length &gt; MAX_FRAME_SIZE (5,242,880 bytes) &#123;<br />
              &nbsp;&nbsp;socket.close_immediately(); // Prevent memory inflation attacks<br />
              &#125;
            </div>
          </section>

          <section className="space-y-3">
            <h2 className="text-2xl font-bold text-white flex items-center gap-2">
              <Shield className="w-5 h-5 text-[#3978F6]" />
              PathSanitizer Directory Traversal Defenses
            </h2>
            <p>
              NEXORA accepts relative directory paths for folder sharing. To defend against arbitrary file overwrites, every relative path passes through <code className="text-white">PathSanitizer</code>:
            </p>
            <ul className="list-disc pl-6 space-y-2 text-slate-300">
              <li>Neutralizes directory traversal sequences: <code className="text-slate-200">../</code>, <code className="text-slate-200">..\</code></li>
              <li>Strips absolute roots: <code className="text-slate-200">/etc/passwd</code>, <code className="text-slate-200">C:\Windows</code></li>
              <li>Rejects Windows reserved device names: <code className="text-slate-200">CON, PRN, AUX, NUL, COM1-9, LPT1-9</code></li>
            </ul>
          </section>

          <section className="space-y-3">
            <h2 className="text-2xl font-bold text-white flex items-center gap-2">
              <AlertTriangle className="w-5 h-5 text-amber-400" />
              Reporting a Vulnerability
            </h2>
            <p>
              If you discover a security issue or vulnerability in NEXORA, please report it responsibly:
            </p>
            <ol className="list-decimal pl-6 space-y-2 text-slate-300">
              <li><strong>Do not create public GitHub issues</strong> for unpatched security exploits.</li>
              <li>Submit a confidential report via <strong>GitHub Private Vulnerability Reporting</strong> on the repository:</li>
            </ol>
            <div className="pt-2">
              <a
                href={RELEASE_INFO.securityAdvisoriesUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[#14243B] text-slate-200 hover:text-white border border-slate-700 hover:border-[#39C6B0] transition-all text-xs font-bold"
              >
                <span>Report via GitHub Security Advisory</span>
                <ExternalLink className="w-3.5 h-3.5" />
              </a>
            </div>
          </section>
        </div>
      </div>
    </div>
  );
};
