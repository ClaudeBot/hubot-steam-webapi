chai = require "chai"
sinon = require "sinon"
chai.use require "sinon-chai"

expect = chai.expect

describe "steam", ->
    beforeEach ->
        @robot =
            respond: sinon.spy()

        require("../src/steam")(@robot)

    it "registers a respond listener", ->
        expect(@robot.respond).to.have.been.calledWith(/steam id( me)? (.+)/i)
        expect(@robot.respond).to.have.been.calledWith(/steam status (.+)/i)
        expect(@robot.respond).to.have.been.calledWith(/dota history (.+)/i)
        expect(@robot.respond).to.have.been.calledWith(/dota match (\d+)\s*(.+)?/i)