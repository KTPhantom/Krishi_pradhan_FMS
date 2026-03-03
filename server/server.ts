import dotenv from 'dotenv';
dotenv.config();

import { App } from './src/app';

const port = process.env.PORT || 3000;
const app = new App();

app.app.listen(port, () => {
    console.log(`🚀 Krishi Pradhan API running on port ${port}`);
});
