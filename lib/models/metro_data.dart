import 'dart:convert';

MetroData metroDataFromJson(String str) => MetroData.fromJson(json.decode(str));

class MetroData {
    final List<MetroLine> lines;

    MetroData({required this.lines});

    factory MetroData.fromJson(Map<String, dynamic> json) => MetroData(
        lines: List<MetroLine>.from(json["lines"].map((x) => MetroLine.fromJson(x))),
    );
}

class MetroLine {
    final String lineId;
    final String lineName;
    final String lineDisplayName;
    final String colorHex;
    final Timings timings;
    final List<Station> stations;

    MetroLine({
        required this.lineId,
        required this.lineName,
        required this.lineDisplayName,
        required this.colorHex,
        required this.timings,
        required this.stations,
    });

    factory MetroLine.fromJson(Map<String, dynamic> json) => MetroLine(
        lineId: json["line_id"],
        lineName: json["line_name"],
        lineDisplayName: json["line_display_name"],
        colorHex: json["color_hex"],
        timings: Timings.fromJson(json["timings"]),
        stations: List<Station>.from(json["stations"].map((x) => Station.fromJson(x))),
    );
}

class Station {
    final String stationId;
    final String stationName;
    final double latitude;
    final double longitude;
    final bool interchange;

    Station({
        required this.stationId,
        required this.stationName,
        required this.latitude,
        required this.longitude,
        required this.interchange,
    });

    factory Station.fromJson(Map<String, dynamic> json) => Station(
        stationId: json["station_id"],
        stationName: json["station_name"],
        latitude: json["latitude"]?.toDouble(),
        longitude: json["longitude"]?.toDouble(),
        interchange: json["interchange"],
    );
}

class Timings {
    final DayTimings weekday;
    final DayTimings sunday;

    Timings({required this.weekday, required this.sunday});

    factory Timings.fromJson(Map<String, dynamic> json) => Timings(
        weekday: DayTimings.fromJson(json["weekday"]),
        sunday: DayTimings.fromJson(json["sunday"]),
    );
}

class DayTimings {
    final String? firstTrain;
    final String? lastTrain;
    final String? frequency;

    DayTimings({
        this.firstTrain,
        this.lastTrain, 
        this.frequency,
    });

    factory DayTimings.fromJson(Map<String, dynamic> json) => DayTimings(
        firstTrain: json["first_train"]?.toString(),
        lastTrain: json["last_train"]?.toString(),
        frequency: json["frequency"]?.toString(),
    );
}

