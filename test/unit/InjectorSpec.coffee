Injector           = require "#{srcDir}/Injector"
DependencyResolver = require "#{srcDir}/DependencyResolver"

describe "Injector", ->

  beforeEach ->
    @injector = Injector.create("injector1")

  it "should exist", ->
    expect(Injector).to.exist
    expect(@injector).to.exist

  it "inject", ->
    @injector.registerFolders __dirname,[
      "../fixtures"
    ]

    @injector.inject (House)->
      expect(House).to.equal """
        House with Pitched Roof and Barn Doors and Double GlazedWindows and Long Garden
      """.trim()

  it "multi injector", ->
    @injector1 = @injector
    @injector2 = Injector.create("injector2")
    @injector1.registerDependencies({
      a:"a"
      b:"b"
    })

    @injector2.registerDependencies({
      a:"a_updated"
      c:"c"
    })
    @injector1.use(@injector2)
    @injector1.inject (a,b,c, $injector)->
      expect([a,b,c]).to.deep.equal [
        "a_updated", "b", "c"
      ]
      expect($injector.getRegex(/./)).to.deep.equal {
        a: 'a_updated', b: 'b', c: 'c'
      }

    @injector1.inject (a,b,c, $injector)->
      expect([a,b,c]).to.deep.equal [
        "a_updated", "b", "c"
      ]
      expect($injector.getRegex(/./)).to.deep.equal {
        a: 'a_updated', b: 'b', c: 'c'
      }

    @injector1.inject ($injector)->
      expect($injector.getRegex(/ssd/)).to.deep.equal {}

    DependencyResolver::throwError = ->

    @injector1.inject ($injector)->
      expect($injector.get("missing")).to.equal null

    error = @injector1.resolver.errors[0]
    console.log error
    expect(error.error).to.equal "Missing Dependency"
    expect(error.callChain.getPath()).to.equal "$$injector1 -> $injector -> missing"


  it "registeration methods", ->
    @injector.registerLibraries({
      "_":"lodash"
      "chai":"chai"
    })

    @injector.inject (_, chai)->
      expect(_.groupBy).to.exist()
      expect(chai.Assertion).to.exist()

  it "dont allow async use of $injector", (done)->

    @injector.registerLibraries({
      "_":"lodash"
      "chai":"chai"
    })

    @injector.addResolvableDependency "foo", ($injector)->
      setTimeout ->
        expect(->
          $injector.get("chai")
        ).to.throw("cannot use $injector.get('chai') asynchronously")
        expect(->
          $injector.getRegex(/.+/)
        ).to.throw("cannot use $injector.getRegex(/.+/) asynchronously")
        done()
      ,0

    @injector.inject (_, chai, $injector, foo)->
