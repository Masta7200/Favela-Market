const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// test route
app.get('/', (req, res) => {
    res.send({ message: "Favela Market API running..." });
});

module.exports = app;
