{spawn, exec} = require 'child_process'

task 'run', 'run project in local mode', (options) =>
    process.env.MONGO_URL = "mongodb://localhost:27017/fundmanager"
    spawn 'mrt', [],
        stdio: 'inherit'
        env: process.env

task 'deploy', 'deploy project to heroku', (options) =>
    spawn 'git', ['push', 'heroku', 'master'], stdio: 'inherit'

task 'pull', 'pull production database to local machine', (options) =>
    spawn 'heroku', ['mongo:pull'], stdio: 'inherit'
