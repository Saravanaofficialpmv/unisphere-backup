"use client";

import { NoiseBackground } from "@/components/ui/noise-background";

export default function NoiseBackgroundDemo() {
  return (
    <div className="flex min-h-screen w-full items-center justify-center p-6">
      {/* Outer area container / card bezel */}
      <NoiseBackground
        containerClassName="w-full max-w-2xl p-3.5 rounded-[28px] shadow-2xl"
        gradientColors={[
          "rgb(255, 100, 150)",
          "rgb(100, 150, 255)",
          "rgb(255, 200, 100)",
        ]}
        speed={0.12}
        noiseIntensity={0.22}
      >
        <div className="flex flex-col items-center justify-center rounded-[20px] bg-white p-8 dark:bg-neutral-900">
          <h2 className="text-xl font-semibold text-neutral-800 dark:text-neutral-100 mb-2">
            Unisphere Platform
          </h2>
          <p className="text-sm text-neutral-500 dark:text-neutral-400 mb-6 text-center max-w-sm">
            Interactive NoiseBackground framing the outer card area with fluid spring physics.
          </p>

          <button className="cursor-pointer rounded-full bg-linear-to-r from-neutral-100 via-neutral-100 to-white px-5 py-2.5 text-black shadow-[0px_2px_0px_0px_var(--color-neutral-50)_inset,0px_0.5px_1px_0px_var(--color-neutral-400)] transition-all duration-100 active:scale-98 dark:from-black dark:via-black dark:to-neutral-900 dark:text-white dark:shadow-[0px_1px_0px_0px_var(--color-neutral-950)_inset,0px_1px_0px_0px_var(--color-neutral-800)]">
            Start publishing &rarr;
          </button>
        </div>
      </NoiseBackground>
    </div>
  );
}
