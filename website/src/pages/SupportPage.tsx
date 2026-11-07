import { useEffect } from 'react';
import { HelpCircle, Bug, MessageSquare, ExternalLink } from 'lucide-react';
import { RELEASE_INFO } from '../constants/releaseInfo';

export const SupportPage = () => {
  useEffect(() => {
    window.scrollTo(0, 0);
  }, []);

  return (
    <div className="py-16 sm:py-24 bg-[#0D1420] text-slate-300">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="mb-12 border-b border-slate-800 pb-8">
          <div className="inline-flex items-center gap-2 px-3.5 py-1 rounded-full bg-[#3978F6]/15 border border-[#3978F6]/30 text-[#3978F6] text-xs font-bold uppercase tracking-wider mb-4">
            <HelpCircle className="w-4 h-4" />
            Support & Community
          </div>
          <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight">
            NEXORA Support & Troubleshooting
          </h1>
          <p className="mt-3 text-sm font-mono text-[#39C6B0]">
            COMMUNITY-DRIVEN • DIRECT GITHUB CHANNELS
          </p>
        </div>

        <div className="space-y-10 leading-relaxed text-sm sm:text-base">
          <section className="space-y-4">
            <h2 className="text-2xl font-bold text-white">Common Troubleshooting Tips</h2>

            <div className="space-y-4">
              <div className="p-5 rounded-2xl bg-[#14243B]/60 border border-slate-800">
                <h3 className="font-bold text-white text-base">Devices not discovering each other?</h3>
                <p className="text-xs text-slate-300 mt-2 leading-relaxed">
                  1. Verify both devices are connected to the exact same Wi-Fi network or portable hotspot.<br />
                  2. Ensure NEXORA is actively open on both devices.<br />
                  3. If on public Wi-Fi (such as a university or hotel), the router may have "AP Isolation" or "Client Isolation" enabled. In this case, use <strong>"Add IP" / "Connect by IP"</strong> or scan the <strong>QR Code</strong> to connect directly.
                </p>
              </div>

              <div className="p-5 rounded-2xl bg-[#14243B]/60 border border-slate-800">
                <h3 className="font-bold text-white text-base">Transfer paused or disconnected in background?</h3>
                <p className="text-xs text-slate-300 mt-2 leading-relaxed">
                  On Android, ensure battery optimization for NEXORA is set to "Unrestricted" so the operating system does not restrict background network execution during multi-gigabyte transfers.
                </p>
              </div>

              <div className="p-5 rounded-2xl bg-[#14243B]/60 border border-slate-800">
                <h3 className="font-bold text-white text-base">Desktop Firewall warnings?</h3>
                <p className="text-xs text-slate-300 mt-2 leading-relaxed">
                  On Windows Defender or Linux UFW, allow inbound/outbound connections for NEXORA on TCP port 48842 (streaming) and UDP port 48843 (discovery).
                </p>
              </div>
            </div>
          </section>

          <section className="space-y-4 pt-4 border-t border-slate-800">
            <h2 className="text-2xl font-bold text-white">Official Support Channels</h2>
            <p>
              Since NEXORA is a free open-source community project, support is provided publicly via GitHub:
            </p>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2">
              <a
                href={RELEASE_INFO.issuesUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="p-5 rounded-2xl bg-[#17243A]/80 border border-slate-700 hover:border-[#3978F6] transition-all block group"
              >
                <div className="w-10 h-10 rounded-xl bg-[#3978F6]/15 text-[#3978F6] flex items-center justify-center mb-3">
                  <Bug className="w-5 h-5" />
                </div>
                <h3 className="text-white font-bold text-base group-hover:text-[#3978F6] transition-colors flex items-center gap-1">
                  <span>Report a Bug</span>
                  <ExternalLink className="w-3.5 h-3.5" />
                </h3>
                <p className="text-xs text-slate-400 mt-1.5 leading-relaxed">
                  Submit detailed bug reports, device logs, and reproduction steps on GitHub Issues.
                </p>
              </a>

              <a
                href={RELEASE_INFO.discussionsUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="p-5 rounded-2xl bg-[#17243A]/80 border border-slate-700 hover:border-[#39C6B0] transition-all block group"
              >
                <div className="w-10 h-10 rounded-xl bg-[#39C6B0]/15 text-[#39C6B0] flex items-center justify-center mb-3">
                  <MessageSquare className="w-5 h-5" />
                </div>
                <h3 className="text-white font-bold text-base group-hover:text-[#39C6B0] transition-colors flex items-center gap-1">
                  <span>Community Discussions</span>
                  <ExternalLink className="w-3.5 h-3.5" />
                </h3>
                <p className="text-xs text-slate-400 mt-1.5 leading-relaxed">
                  Ask questions, request features, share network setup tips, and engage with other users.
                </p>
              </a>
            </div>
          </section>
        </div>
      </div>
    </div>
  );
};
