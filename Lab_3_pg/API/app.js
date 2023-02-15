const express = require('express')
const cors = require('cors')
const morgan = require('morgan')
const client = require('./Config/db')


//DB
client.connect((err) => {
    if (err) {
        console.error('Error connecting to the database:', err.stack)
    } else {
        console.log('Connected to the database.')
    }
})

//express
const app = express()
app.use(cors())
app.use(express.json())
app.use(morgan('combined'))

// route get version
app.get("/api", (req, res) => {
    res.send({ message: "API v.1.0.0" })
});

// plaquage OK
// route get plaquage OK
app.get('/plaquage-ok/get', (req, res) => {
    client.query(`SELECT * FROM plaquage_ok`, (err, result) => {
        if (!err) {
            res.send(result.rows)
        }
    });
    client.end
})
// route add plaquage OK
app.post('/plaquage-ok/add', (req, res) => {
    let insertQuery = `UPDATE plaquage_ok SET sum_plaquage_ok=sum_plaquage_ok+1 WHERE Id = 1`

    client.query(insertQuery, (err, result) => {
        if (!err) {
            res.send('add plaquage ok !')
        }
        else { console.log(err.message) }
    })
    client.end
})
// route reset plaquage OK
app.post('/plaquage-ok/reset', (req, res) => {
    let insertQuery = `UPDATE plaquage_ok SET sum_plaquage_ok = 0 where id = 1`
    client.query(insertQuery, (err, result) => {
        if (!err) {
            res.send('reset plaquage ok !')
        }
        else { console.log(err.message) }
    })
    client.end
})

// plaquage KO
// route get plaquage KO
app.get('/plaquage-ko/get', (req, res) => {
    client.query(`SELECT * FROM plaquage_ko`, (err, result) => {
        if (!err) {
            res.send(result.rows)
        }
    });
    client.end
})
// route add plaquage KO
app.post('/plaquage-ko/add', (req, res) => {
    let insertQuery = `UPDATE plaquage_ko SET sum_plaquage_ko=sum_plaquage_ko+1 WHERE Id = 1`

    client.query(insertQuery, (err, result) => {
        if (!err) {
            res.send('add plaquage ko !')
        }
        else { console.log(err.message) }
    })
    client.end
})
// route reset plaquage KO
app.post('/plaquage-ko/reset', (req, res) => {
    let insertQuery = `UPDATE plaquage_ko SET sum_plaquage_ko = 0 where id = 1`
    client.query(insertQuery, (err, result) => {
        if (!err) {
            res.send('reset plaquage ko !')
        }
        else { console.log(err.message) }
    })
    client.end
})

// app sur le port 3000
app.listen(3000, () => {
    console.log('app listening on port 3000!')
})