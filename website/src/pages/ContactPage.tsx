import { useEffect } from 'react';
import { User, ExternalLink } from 'lucide-react';
import { GithubIcon } from '../components/GithubIcon';
import { RELEASE_INFO } from '../constants/releaseInfo';

export const ContactPage = () => {
  useEffect(() => {
    window.scrollTo(0, 0);
  }, []);

  return (
    <div className="py-16 sm:py-24 bg-[#0D1420] text-slate-300">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="mb-12 border-b border-slate-800 pb-8">
          <div className="inline-flex items-center gap-2 px-3.5 py-1 rounded-full bg-[#39C6B0]/15 border border-[#39C6B0]/30 text-[#39C6B0] text-xs font-bold uppercase tracking-wider mb-4">
            <User className="w-4 h-4" />
            Maintainer & Contact
          </div>
          <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight">
            Developer Contact & Collaboration
          </h1>
          <p className="mt-3 text-sm font-mono text-[#3978F6]">
            OPEN SOURCE LEADERSHIP • VERIFIED GITHUB CHANNELS
          </p>
        </div>

        <div className="space-y-10 leading-relaxed text-sm sm:text-base">
          {/* Developer Profile Card */}
          <div className="p-8 rounded-3xl bg-gradient-to-br from-[#17243A] to-[#14243B] border border-slate-700 shadow-xl">
            <div className="flex flex-col sm:flex-row items-center sm:items-start gap-6">
              <div className="w-20 h-20 rounded-2xl bg-[#0D1420] border-2 border-[#3978F6] flex items-center justify-center shrink-0 shadow-lg">
                <span className="text-[#39C6B0] font-black text-3xl">A</span>
              </div>

              <div className="space-y-3 text-center sm:text-left">
                <div>
                  <h3 className="text-2xl font-bold text-white">CodeByArnob</h3>
                  <p className="text-xs font-mono text-[#39C6B0] mt-0.5">Project Creator & Lead Maintainer</p>
                </div>

                <p className="text-sm text-slate-300 max-w-xl leading-relaxed">
                  Architect of NEXORA's cross-platform peer-to-peer file sharing platform, combining Rust zero-copy network concurrency with Flutter Material 3 reactive presentation.
                </p>

                <div className="pt-2 flex flex-wrap items-center justify-center sm:justify-start gap-3">
                  <a
                    href={RELEASE_INFO.maintainerUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-[#0D1420] text-white hover:bg-slate-800 border border-slate-700 text-xs font-bold transition-all shadow"
                  >
                    <GithubIcon className="w-4 h-4" />
                    <span>GitHub Profile (@CodeByArnob)</span>
                    <ExternalLink className="w-3 h-3 text-slate-400" />
                  </a>

                  <a
                    href={RELEASE_INFO.repoUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-[#3978F6] text-white hover:bg-[#2563EB] text-xs font-bold transition-all shadow"
                  >
                    <span>Nexora-share Repository</span>
                    <ExternalLink className="w-3 h-3 text-white" />
                  </a>
                </div>
              </div>
            </div>
          </div>

          <section className="space-y-4">
            <h2 className="text-2xl font-bold text-white">How to Reach the Project</h2>
            <p>
              To maintain transparency, privacy, and open collaboration, all communications are handled through verified GitHub channels:
            </p>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 pt-2">
              <div className="p-4 rounded-xl bg-[#14243B]/50 border border-slate-800">
                <h4 className="font-bold text-white text-sm mb-1">Feature Requests</h4>
                <p className="text-xs text-slate-400 mb-3">Share ideas for new platforms, protocol optimizations, or UX improvements.</p>
                <a href={RELEASE_INFO.discussionsUrl} target="_blank" rel="noopener noreferrer" className="text-xs text-[#39C6B0] hover:underline font-bold flex items-center gap-1">
                  Discussions <ExternalLink className="w-3 h-3" />
                </a>
              </div>

              <div className="p-4 rounded-xl bg-[#14243B]/50 border border-slate-800">
                <h4 className="font-bold text-white text-sm mb-1">Bug Reports</h4>
                <p className="text-xs text-slate-400 mb-3">Report defects, discovery glitches, or platform-specific runtime issues.</p>
                <a href={RELEASE_INFO.issuesUrl} target="_blank" rel="noopener noreferrer" className="text-xs text-[#3978F6] hover:underline font-bold flex items-center gap-1">
                  Issue Tracker <ExternalLink className="w-3 h-3" />
                </a>
              </div>

              <div className="p-4 rounded-xl bg-[#14243B]/50 border border-slate-800">
                <h4 className="font-bold text-white text-sm mb-1">Security Advisories</h4>
                <p className="text-xs text-slate-400 mb-3">Confidential vulnerability disclosure via private GitHub Advisories.</p>
                <a href={RELEASE_INFO.securityAdvisoriesUrl} target="_blank" rel="noopener noreferrer" className="text-xs text-[#39C6B0] hover:underline font-bold flex items-center gap-1">
                  Advisory Portal <ExternalLink className="w-3 h-3" />
                </a>
              </div>
            </div>
          </section>
        </div>
      </div>
    </div>
  );
};
