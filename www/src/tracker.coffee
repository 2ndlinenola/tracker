serverHost = "http://secondline-server.herokuapp.com"
serverPort = 80
#serverHost = "http://localhost"
#serverPort = 5000

class Map
  constructor: ->
    center = new google.maps.LatLng 29.9511782,-90.0689848 # Jackson square!
    @marker = null

    @map = new google.maps.Map document.getElementById("map_canvas"),
      disableDefaultUI: true
      draggable:        false
      zoom:             15
      center:           center
      mapTypeId:        google.maps.MapTypeId.ROADMAP

  setPosition: (lat, lng) ->
    if @marker?
      @marker.setMap null
      @marker = null

    position = new google.maps.LatLng lat, lng

    @marker = new google.maps.Marker
      position: position
      map:      @map
      title: "position"

    @map.setCenter position

class Ui
  start: ->
    @map = new Map
    @socket = io.connect serverHost,
      transports: ["xhr-polling"]
      port:       serverPort

    @socket.on "position", @onPosition

    $("#position").text "Waiting for position.."

  onPosition: (position) =>
    $("#position").html """
      Latitude: #{position.latitude}<br/>
      Longitude: #{position.longitude}
                        """

    @map.setPosition position.latitude, position.longitude

class BackgroundTracking
  constructor: ->
    @serverUrl = "#{serverHost}/report.json"

    window.navigator.geolocation.getCurrentPosition -> # Dummy to prompt for right

    @bgGeo = window.plugins.backgroundGeoLocation

    @bgGeo.configure @onPosition, @onFailure,
      url:              @serverUrl
      desiredAccuracy:  0
      stationaryRadius: 20
      distanceFilter:   30

  start: ->
    @bgGeo.start()

  onPosition: (position) =>
    $.post @serverUrl, {location: position}, null, "json"
    @bgGeo.finish()

  onFailure: (error) =>
    console.log "error", error

class window.Tracker
  constructor: ->
    document.addEventListener "deviceready", @onReady, false

  onReady: =>
    @ui       = new Ui
    @tracking = new BackgroundTracking

    @ui.start()
    @tracking.start()
