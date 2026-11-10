import { defineConfig } from "vite";

export default {
  vite: defineConfig({}),
  headTagsTemplate(context) {
    return `
<link rel="stylesheet" href="/style.css" />
<link rel="icon" href="/favicon.png" />
<meta name="theme-color" content="#ffffff" />
`;
  },
  preloadTagForFile(file) {
    return !file.endsWith(".css");
  },
};
