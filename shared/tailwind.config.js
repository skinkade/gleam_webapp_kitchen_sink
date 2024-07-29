/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{html,js,gleam}"],
  theme: {
    extend: {},
  },
  plugins: [require('daisyui')],
  daisyui: {
    themes: ["light"],
  },
}

