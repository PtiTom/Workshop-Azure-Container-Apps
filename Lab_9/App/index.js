const express = require('express');
const morgan = require('morgan');

const app = express();
app.use(morgan('combined'));

app.get('/', (req, res) => {
    res.sendFile(__dirname + '/index.html')
});

app.listen(3000, () => {
    console.log('app listening on port 3000!');
});



