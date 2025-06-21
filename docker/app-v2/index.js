const express = require('express');
const app = express();
app.get('/', (_, res) => res.send('Hello from App Version v2 (Canary)'));
app.listen(3000);