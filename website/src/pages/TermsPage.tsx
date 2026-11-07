import { useEffect } from 'react';
import { FileText, ExternalLink } from 'lucide-react';
import { RELEASE_INFO } from '../constants/releaseInfo';

export const TermsPage = () => {
  useEffect(() => {
    window.scrollTo(0, 0);
  }, []);

  return (
    <div className="py-16 sm:py-24 bg-[#0D1420] text-slate-300">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="mb-12 border-b border-slate-800 pb-8">
          <div className="inline-flex items-center gap-2 px-3.5 py-1 rounded-full bg-[#3978F6]/15 border border-[#3978F6]/30 text-[#3978F6] text-xs font-bold uppercase tracking-wider mb-4">
            <FileText className="w-4 h-4" />
            Terms of Use
          </div>
          <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight">
            NEXORA Terms of Use
          </h1>
          <p className="mt-3 text-sm font-mono text-[#39C6B0]">
            APACHE LICENSE 2.0 • OPEN SOURCE TERMS
          </p>
          <div className="mt-4 text-xs text-slate-400 font-mono">
            <span>Last Updated: November 7, 2026</span>
          </div>
        </div>

        <div className="space-y-8 leading-relaxed text-sm sm:text-base">
          <section className="space-y-3">
            <h2 className="text-xl font-bold text-white">1. Acceptance of Terms</h2>
            <p>
              By downloading, compiling, installing, or using the NEXORA software, you agree to comply with and be bound by these Terms of Use and the <strong>Apache License 2.0</strong>. If you do not agree, do not use the software.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-white">2. Open Source License</h2>
            <p>
              NEXORA is free, open-source software licensed under the <strong>Apache License, Version 2.0</strong>. You are granted rights to use, inspect, copy, modify, merge, publish, and distribute the code in accordance with the license conditions.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-white">3. User Responsibility & Lawful Use</h2>
            <p>
              NEXORA is an unmediated, peer-to-peer data transmission tool. You are solely responsible for all files, data, and content you transmit or receive using the application:
            </p>
            <ul className="list-disc pl-6 space-y-1 text-slate-300 text-sm">
              <li>You agree not to use NEXORA to transmit malicious software, viruses, or unauthorized copyright-infringing materials.</li>
              <li>You agree to comply with all applicable local, national, and international laws governing data transmission.</li>
              <li>Because NEXORA has zero cloud servers, the developers and maintainers have no ability, access, or technical mechanism to inspect, filter, log, block, or recover transferred data.</li>
            </ul>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-white">4. Disclaimer of Warranty</h2>
            <div className="p-4 rounded-xl bg-[#14243B]/60 border border-slate-800 text-xs sm:text-sm text-slate-300 font-mono">
              THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY.
            </div>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-white">5. Contact & Inquiries</h2>
            <p>
              For questions concerning software terms or open source licensing, open a discussion or issue at:
            </p>
            <div className="pt-1">
              <a
                href={RELEASE_INFO.repoUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="text-[#3978F6] hover:underline flex items-center gap-1 font-bold"
              >
                <span>https://github.com/CodeByArnob/Nexora-share</span>
                <ExternalLink className="w-3.5 h-3.5" />
              </a>
            </div>
          </section>
        </div>
      </div>
    </div>
  );
};
