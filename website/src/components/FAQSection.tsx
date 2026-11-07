import React, { useState } from 'react';
import { ChevronDown, HelpCircle } from 'lucide-react';

interface FAQItem {
  question: string;
  answer: string;
}

const FAQS: FAQItem[] = [
  {
    question: 'Does NEXORA require an active Internet connection?',
    answer:
      'No. NEXORA works completely offline. All file discovery and streaming occur directly over your local Wi-Fi network, local Ethernet LAN, or Android portable hotspot. No cellular data or external Internet connection is ever used.',
  },
  {
    question: 'Are my files or metadata uploaded to any remote server or cloud?',
    answer:
      'Never. NEXORA has zero cloud servers, zero telemetry, zero analytics SDKs, and zero accounts. Files flow directly from device to device over encrypted local TCP sockets. No intermediary ever touches or logs your data.',
  },
  {
    question: 'How does NEXORA work on public Wi-Fi with AP Isolation (Client Isolation)?',
    answer:
      'On corporate, hotel, or university Wi-Fi networks that block UDP broadcast/multicast packets between clients, NEXORA provides a Direct IP Connect fallback. Simply enter the other device’s IP address (shown on their home screen) or scan their pairing QR code to connect directly over TCP.',
  },
  {
    question: 'Can I transfer multi-gigabyte files (5GB, 10GB+) without crashing?',
    answer:
      'Yes. NEXORA uses true streaming file transfer with a bounded 1MB RAM buffer and receiver flow-control backpressure. It never loads entire files into memory, keeping RAM usage strictly under 30MB regardless of file size.',
  },
  {
    question: 'Will active transfers continue if I lock my phone or switch apps?',
    answer:
      'Yes on Android. NEXORA implements a properly declared Android Foreground Service with dataSync foreground execution type and persistent notification, ensuring transfers continue smoothly when you leave the app or lock the screen.',
  },
  {
    question: 'What happens if a transfer is interrupted by a network drop?',
    answer:
      'NEXORA features verified checkpoint resumption. Every 1MB chunk is cryptographically verified via SHA-256 and recorded in a local SQLite ledger. When reconnected, the transfer automatically resumes from the last verified chunk instead of starting over.',
  },
  {
    question: 'How do I delete transfer history or revoke trusted devices?',
    answer:
      'All transfer records and trusted device fingerprints are stored exclusively in your local device SQLite database. You can inspect, revoke trust, or clear history at any time from within the app settings.',
  },
];

export const FAQSection: React.FC = () => {
  const [openIndex, setOpenIndex] = useState<number | null>(0);

  const toggle = (idx: number) => {
    setOpenIndex(openIndex === idx ? null : idx);
  };

  return (
    <section id="faq" className="py-24 bg-[#0D1420] border-t border-slate-800">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-3xl mx-auto mb-16">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#39C6B0]/10 border border-[#39C6B0]/30 text-[#39C6B0] text-xs font-semibold uppercase tracking-wider mb-4">
            <HelpCircle className="w-3.5 h-3.5" />
            Frequently Asked Questions
          </div>
          <h2 className="text-3xl sm:text-4xl font-extrabold text-white tracking-tight">
            Clear Answers to Technical Questions
          </h2>
          <p className="mt-4 text-base text-slate-300">
            Everything you need to know about NEXORA's architecture, security, and privacy guarantees.
          </p>
        </div>

        <div className="space-y-4">
          {FAQS.map((faq, idx) => {
            const isOpen = openIndex === idx;
            return (
              <div
                key={idx}
                className="rounded-2xl bg-[#14243B]/50 border border-slate-800 transition-all overflow-hidden"
              >
                <button
                  onClick={() => toggle(idx)}
                  className="w-full flex items-center justify-between p-5 sm:p-6 text-left font-bold text-white hover:text-[#39C6B0] transition-colors focus:outline-none"
                >
                  <span className="text-base sm:text-lg pr-4">{faq.question}</span>
                  <ChevronDown
                    className={`w-5 h-5 text-slate-400 shrink-0 transition-transform duration-200 ${
                      isOpen ? 'rotate-180 text-[#39C6B0]' : ''
                    }`}
                  />
                </button>
                {isOpen && (
                  <div className="px-5 pb-6 sm:px-6 pt-1 text-sm text-slate-300 leading-relaxed border-t border-slate-800/60">
                    {faq.answer}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
};
