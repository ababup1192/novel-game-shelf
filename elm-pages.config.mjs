import { defineConfig } from "vite";

export default {
  vite: defineConfig({}),
  headTagsTemplate(context) {
    return `
<link rel="preconnect" href="https://fonts.googleapis.com" />
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=M+PLUS+Rounded+1c:wght@400;700;800;900&display=swap" />
<link rel="stylesheet" href="/style.css" />
<link rel="icon" href="/favicon.png" />
<meta name="theme-color" content="#ffffff" />
`;
  },
  preloadTagForFile(file) {
    return !file.endsWith(".css");
  },
};
