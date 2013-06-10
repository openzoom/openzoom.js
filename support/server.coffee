express = require 'express'
path = require 'path'
{exec} = require 'child_process'


# Constants
HOST = process.argv[4] ? 'localhost'
PORT = parseInt process.argv[2] ? 8000, 10
PATH = process.argv[3] ? '/'
URL = "http://#{HOST}:#{PORT}#{PATH}"

# App
app = express.createServer()
app.use express.static path.join __dirname, '..'
app.listen PORT

# Open browser
exec "open #{URL}"
