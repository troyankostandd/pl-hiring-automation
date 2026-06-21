/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/views/**/*.{erb,html}',
    './app/components/**/*.{rb,erb,html}',
    './app/helpers/**/*.rb',
  ],
  theme: {
    extend: {
      colors: {
        ink: '#1A1A1A',
        paper: '#FAFAF7',
        'paper-2': '#F2F1EC',
        olive: '#5D6B3A',
        persimmon: '#D9542B',
        smoke: '#6B6B66',
      },
      fontFamily: {
        display: ['Fraunces', 'Georgia', 'serif'],
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },
      fontSize: {
        xs: '12px',
        sm: '14px',
        base: '16px',
        md: '18px',
        lg: '24px',
        xl: '32px',
        '2xl': '48px',
        '3xl': '72px',
      },
      lineHeight: {
        display: '1.1',
        body: '1.5',
      },
      borderRadius: {
        none: '0',
        sm: '2px',
        DEFAULT: '4px',
      },
      spacing: {
        // Uses default Tailwind 4px scale
      },
    },
  },
  plugins: [
    require('@tailwindcss/typography'),
  ],
}
