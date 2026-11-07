import React, { useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import { HeroSection } from '../components/HeroSection';
import { AppScreenshotShowcase } from '../components/AppScreenshotShowcase';
import { FeatureGrid } from '../components/FeatureGrid';
import { ArchitectureSection } from '../components/ArchitectureSection';
import { CompatibilityMatrix } from '../components/CompatibilityMatrix';
import { DownloadSection } from '../components/DownloadSection';
import { FAQSection } from '../components/FAQSection';

export const HomePage: React.FC = () => {
  const location = useLocation();

  useEffect(() => {
    if (location.hash) {
      const element = document.querySelector(location.hash);
      if (element) {
        element.scrollIntoView({ behavior: 'smooth' });
      }
    } else {
      window.scrollTo(0, 0);
    }
  }, [location]);

  return (
    <div className="flex flex-col min-h-screen">
      <HeroSection />
      <AppScreenshotShowcase />
      <FeatureGrid />
      <ArchitectureSection />
      <CompatibilityMatrix />
      <DownloadSection />
      <FAQSection />
    </div>
  );
};
