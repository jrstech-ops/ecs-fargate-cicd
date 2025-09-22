const express = require('express');
const app = express();
app.get('/', (req, res) => res.send('Hello Jomari!Welcome back from ECS Fargate ECS 2025'));
app.listen(3000, () => console.log('App running on port 3000'));

