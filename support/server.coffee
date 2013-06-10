exec = require('child_process').exec
express = require 'express'
path = require 'path'


# Constants
HOST = process.argv[4] or 'localhost'
PORT = parseInt(process.argv[2] or 8142, 10)
PATH = process.argv[3] or '/'
URL = "http://#{HOST}:#{PORT}#{PATH}"

# App
app = express.createServer()
app.use(express.static(path.join(__dirname, '../ben')))
app.listen PORT

# Open browser
exec "open #{URL}"
