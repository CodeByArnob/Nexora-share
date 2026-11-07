import { useEffect } from 'react';
import { Award } from 'lucide-react';

export const LicensesPage = () => {
  useEffect(() => {
    window.scrollTo(0, 0);
  }, []);

  return (
    <div className="py-16 sm:py-24 bg-[#0D1420] text-slate-300">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="mb-12 border-b border-slate-800 pb-8">
          <div className="inline-flex items-center gap-2 px-3.5 py-1 rounded-full bg-[#39C6B0]/15 border border-[#39C6B0]/30 text-[#39C6B0] text-xs font-bold uppercase tracking-wider mb-4">
            <Award className="w-4 h-4" />
            Open Source Governance
          </div>
          <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight">
            Open Source Licenses & Credits
          </h1>
          <p className="mt-3 text-sm font-mono text-[#3978F6]">
            APACHE LICENSE 2.0 • ACKNOWLEDGEMENTS
          </p>
        </div>

        <div className="space-y-10 leading-relaxed text-sm sm:text-base">
          <section className="space-y-4">
            <h2 className="text-2xl font-bold text-white">NEXORA Primary License</h2>
            <p>
              NEXORA is free software created and maintained by <strong>CodeByArnob</strong> and open source contributors under the terms of the <strong>Apache License, Version 2.0</strong>.
            </p>
            <div className="p-5 bg-[#0A0F18] border border-slate-800 rounded-2xl font-mono text-xs text-slate-400 overflow-x-auto space-y-2">
              <p className="text-white font-bold">Apache License, Version 2.0 (January 2004)</p>
              <p>http://www.apache.org/licenses/LICENSE-2.0</p>
              <p className="pt-2 text-slate-300">
                Licensed under the Apache License, Version 2.0 (the "License");
                you may not use this file except in compliance with the License.
                You may obtain a copy of the License at
              </p>
              <p className="text-[#3978F6]">http://www.apache.org/licenses/LICENSE-2.0</p>
              <p className="pt-2 text-slate-300">
                Unless required by applicable law or agreed to in writing, software
                distributed under the License is distributed on an "AS IS" BASIS,
                WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
                See the License for the specific language governing permissions and
                limitations under the License.
              </p>
            </div>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl font-bold text-white">Core Technology Acknowledgements</h2>
            <p>
              NEXORA stands on the shoulders of the global open source community:
            </p>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="p-4 rounded-xl bg-[#14243B]/60 border border-slate-800">
                <h4 className="font-bold text-white text-base">Flutter & Dart SDK</h4>
                <p className="text-xs text-slate-400 mt-1">BSD 3-Clause License • Google LLC</p>
                <p className="text-xs text-slate-300 mt-2">Declarative reactive cross-platform UI and Impeller Vulkan engine.</p>
              </div>

              <div className="p-4 rounded-xl bg-[#14243B]/60 border border-slate-800">
                <h4 className="font-bold text-white text-base">Rust Language & Tokio</h4>
                <p className="text-xs text-slate-400 mt-1">MIT / Apache 2.0 License • Tokio Contributors</p>
                <p className="text-xs text-slate-300 mt-2">Async event-driven zero-copy I/O runtime and high-performance threading.</p>
              </div>

              <div className="p-4 rounded-xl bg-[#14243B]/60 border border-slate-800">
                <h4 className="font-bold text-white text-base">SQLite Database Engine</h4>
                <p className="text-xs text-slate-400 mt-1">Public Domain • D. Richard Hipp</p>
                <p className="text-xs text-slate-300 mt-2">In-process transactional SQL engine storing resume checkpoints and trusted device keys.</p>
              </div>

              <div className="p-4 rounded-xl bg-[#14243B]/60 border border-slate-800">
                <h4 className="font-bold text-white text-base">Riverpod State Architecture</h4>
                <p className="text-xs text-slate-400 mt-1">MIT License • Remi Rousselet</p>
                <p className="text-xs text-slate-300 mt-2">Compile-safe, testable reactive state management for Flutter.</p>
              </div>
            </div>
          </section>
        </div>
      </div>
    </div>
  );
};
