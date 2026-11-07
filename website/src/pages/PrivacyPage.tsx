import { useEffect } from 'react';
import { Shield, Lock, ServerOff, EyeOff, ExternalLink } from 'lucide-react';
import { RELEASE_INFO } from '../constants/releaseInfo';

export const PrivacyPage = () => {
  useEffect(() => {
    window.scrollTo(0, 0);
  }, []);

  return (
    <div className="py-16 sm:py-24 bg-[#0D1420] text-slate-300">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header Badge & Title */}
        <div className="mb-12 border-b border-slate-800 pb-8">
          <div className="inline-flex items-center gap-2 px-3.5 py-1 rounded-full bg-[#39C6B0]/15 border border-[#39C6B0]/30 text-[#39C6B0] text-xs font-bold uppercase tracking-wider mb-4">
            <Shield className="w-4 h-4" />
            Official Privacy Policy
          </div>
          <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight">
            NEXORA Privacy Policy
          </h1>
          <p className="mt-3 text-sm font-mono text-[#3978F6]">
            PRIVATE BY DESIGN. OPEN BY NATURE.
          </p>
          <div className="mt-4 flex flex-wrap gap-4 text-xs text-slate-400 font-mono">
            <span>Effective Date: <strong>November 7, 2026</strong></span>
            <span>•</span>
            <span>Policy Version: <strong>1.0.0</strong></span>
            <span>•</span>
            <span>Product: <strong>io.github.codebyarnob.nexora</strong></span>
          </div>
        </div>

        {/* Core Guarantee Callout */}
        <div className="p-6 sm:p-8 rounded-3xl bg-[#14243B]/60 border-2 border-[#39C6B0]/40 mb-12 shadow-xl shadow-[#39C6B0]/5">
          <div className="flex items-start gap-4">
            <div className="w-12 h-12 rounded-2xl bg-[#39C6B0]/15 text-[#39C6B0] flex items-center justify-center shrink-0">
              <ServerOff className="w-6 h-6" />
            </div>
            <div>
              <h3 className="text-xl font-bold text-white">Our Foundational Privacy Guarantee</h3>
              <p className="text-sm text-slate-300 mt-2 leading-relaxed">
                NEXORA does <strong>NOT</strong> operate cloud servers, signaling relays, account databases, or telemetry trackers. When you share files with NEXORA, your data is transmitted directly between devices on your local Wi-Fi or mobile hotspot. <strong>Zero files, zero metadata, and zero metrics ever leave your local network.</strong>
              </p>
            </div>
          </div>
        </div>

        {/* Policy Sections */}
        <div className="space-y-12 leading-relaxed text-sm sm:text-base">
          {/* Section 1 */}
          <section className="space-y-4">
            <h2 className="text-2xl font-bold text-white flex items-center gap-2">
              <span className="text-[#3978F6]">1.</span> Zero Cloud & Zero Account Architecture
            </h2>
            <p>
              Unlike traditional cloud storage or internet-mediated transfer tools, NEXORA requires:
            </p>
            <ul className="list-disc pl-6 space-y-2 text-slate-300">
              <li><strong>No User Accounts:</strong> You are never asked for an email address, phone number, username, or password.</li>
              <li><strong>No Cloud File Hosting:</strong> NEXORA maintains no cloud storage buckets, remote staging servers, or central caches.</li>
              <li><strong>No Third-Party Brokers:</strong> All connections are established directly between device IP addresses over local TCP and UDP sockets.</li>
            </ul>
          </section>

          {/* Section 2 */}
          <section className="space-y-4">
            <h2 className="text-2xl font-bold text-white flex items-center gap-2">
              <span className="text-[#3978F6]">2.</span> Zero Telemetry, Analytics, or Tracking
            </h2>
            <p>
              We believe privacy is an absolute right, not a setting:
            </p>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2">
              <div className="p-4 rounded-xl bg-[#17243A]/60 border border-slate-800">
                <h4 className="font-bold text-white text-sm flex items-center gap-2">
                  <EyeOff className="w-4 h-4 text-[#39C6B0]" />
                  No Analytics SDKs
                </h4>
                <p className="text-xs text-slate-400 mt-1">
                  The application contains zero Google Analytics, Firebase Analytics, Mixpanel, or third-party usage profiling libraries.
                </p>
              </div>
              <div className="p-4 rounded-xl bg-[#17243A]/60 border border-slate-800">
                <h4 className="font-bold text-white text-sm flex items-center gap-2">
                  <Lock className="w-4 h-4 text-[#39C6B0]" />
                  No Remote Crash Reports
                </h4>
                <p className="text-xs text-slate-400 mt-1">
                  Stack traces and diagnostic logs are strictly confined to your local device. We never automatically harvest crash dumps.
                </p>
              </div>
            </div>
          </section>

          {/* Section 3 */}
          <section className="space-y-4">
            <h2 className="text-2xl font-bold text-white flex items-center gap-2">
              <span className="text-[#3978F6]">3.</span> Local Storage & Data Retention
            </h2>
            <p>
              All application state is preserved solely in a local SQLite database (<code className="text-[#39C6B0]">nexora.db</code>) on your device:
            </p>
            <ul className="list-disc pl-6 space-y-2 text-slate-300">
              <li><strong>Device Cryptographic Fingerprint:</strong> Generated locally during installation (SHA-256 hash). Never exported or published.</li>
              <li><strong>Transfer History:</strong> Records transfer direction, peer display name, total files, total byte count, and completion timestamps. <em>Actual file contents or payload bytes are never stored in the database.</em></li>
              <li><strong>Trusted Devices:</strong> Public key fingerprints and user-assigned nicknames of paired devices.</li>
            </ul>
            <div className="p-4 rounded-xl bg-[#14243B]/40 border border-slate-800 mt-4">
              <h4 className="text-xs uppercase font-mono tracking-widest text-[#3978F6] font-bold">
                How to Delete Your Data
              </h4>
              <p className="text-xs text-slate-300 mt-1">
                You can delete all transfer history or revoke trusted devices at any time by navigating to <strong>Settings</strong> within the NEXORA app. Uninstalling the app completely purges all SQLite databases from your device.
              </p>
            </div>
          </section>

          {/* Section 4 */}
          <section className="space-y-4">
            <h2 className="text-2xl font-bold text-white flex items-center gap-2">
              <span className="text-[#3978F6]">4.</span> Android OS Permissions & Justification
            </h2>
            <p>
              NEXORA requests only standard Android permissions strictly necessary for local network operation:
            </p>
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs border border-slate-800 rounded-xl overflow-hidden">
                <thead className="bg-[#14243B] text-slate-200">
                  <tr>
                    <th className="p-3">Permission</th>
                    <th className="p-3">Exact Technical Purpose</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800 text-slate-300 bg-[#0D1420]">
                  <tr>
                    <td className="p-3 font-mono text-[#3978F6]">INTERNET</td>
                    <td className="p-3">Create local TCP and UDP sockets for device discovery and file streaming on LAN.</td>
                  </tr>
                  <tr>
                    <td className="p-3 font-mono text-[#3978F6]">ACCESS_NETWORK_STATE / ACCESS_WIFI_STATE</td>
                    <td className="p-3">Determine active Wi-Fi interface and compute directed subnet broadcast addresses (192.168.x.255).</td>
                  </tr>
                  <tr>
                    <td className="p-3 font-mono text-[#3978F6]">CHANGE_WIFI_MULTICAST_STATE</td>
                    <td className="p-3">Acquire WifiManager.MulticastLock so Android Wi-Fi chipsets do not discard incoming discovery packets during power-saving.</td>
                  </tr>
                  <tr>
                    <td className="p-3 font-mono text-[#3978F6]">FOREGROUND_SERVICE_DATA_SYNC</td>
                    <td className="p-3">Keep file transmissions alive in the background when the user locks their screen or navigates away.</td>
                  </tr>
                  <tr>
                    <td className="p-3 font-mono text-[#3978F6]">POST_NOTIFICATIONS</td>
                    <td className="p-3">Display active transfer progress and speed notification while foreground transfer service is active.</td>
                  </tr>
                  <tr>
                    <td className="p-3 font-mono text-[#3978F6]">WAKE_LOCK</td>
                    <td className="p-3">Prevent CPU deep sleep from aborting multi-gigabyte file stream writes.</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>

          {/* Section 5 */}
          <section className="space-y-4">
            <h2 className="text-2xl font-bold text-white flex items-center gap-2">
              <span className="text-[#3978F6]">5.</span> Explicit Receiver Consent
            </h2>
            <p>
              NEXORA strictly prohibits unsolicited incoming transfers. Senders cannot push files silently. The receiver is presented with an explicit approval prompt containing the sender's device name, file count, file manifest, and total size. No socket writes to disk occur until the receiver explicitly taps <strong>Accept</strong>.
            </p>
          </section>

          {/* Section 6 */}
          <section className="space-y-4">
            <h2 className="text-2xl font-bold text-white flex items-center gap-2">
              <span className="text-[#3978F6]">6.</span> Open Source Auditing & Contact
            </h2>
            <p>
              NEXORA is 100% open source under the <strong>Apache License 2.0</strong>. Every line of code governing network communication, cryptographic key generation, and local persistence is publicly auditable.
            </p>
            <p>
              If you have any questions, privacy concerns, or security observations, please open an issue or security advisory on our official repository:
            </p>
            <div className="pt-2">
              <a
                href={RELEASE_INFO.issuesUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[#14243B] text-slate-200 hover:text-white border border-slate-700 hover:border-[#39C6B0] transition-all text-xs font-bold"
              >
                <span>Report Issue on GitHub Issues</span>
                <ExternalLink className="w-3.5 h-3.5" />
              </a>
            </div>
          </section>
        </div>
      </div>
    </div>
  );
};
