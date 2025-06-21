const express = require('express');
const app = express();
app.get('/', (_, res) => res.send('Hello from App Version v1 (Stable)'));
app.listen(3000);