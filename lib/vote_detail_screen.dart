import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart'; // For PdfColor.
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class VoteDetailScreen extends StatelessWidget {
  final String eventId;

  const VoteDetailScreen({required this.eventId});

  /// Fetches candidate vote data from Firestore.
  /// For each candidate document within the "scoreboard" subcollection,
  /// it retrieves vote documents, calculates cumulative totals and averages,
  /// and returns a sorted list of candidate data.
  Future<List<Map<String, dynamic>>> fetchCandidatesData() async {
    QuerySnapshot scoreboardSnapshot = await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .collection('scoreboard')
        .get();

    List<Map<String, dynamic>> candidateData = [];

    for (var candidateDoc in scoreboardSnapshot.docs) {
      String contestant = candidateDoc.id;
      QuerySnapshot votesSnapshot = await candidateDoc.reference
          .collection('votes')
          .orderBy('timestamp', descending: false)
          .get();

      double totalScore = 0.0;
      int voteCount = 0;
      List<Map<String, dynamic>> votesList = [];

      for (var voteDoc in votesSnapshot.docs) {
        Map<String, dynamic> voteData =
            voteDoc.data() as Map<String, dynamic>;
        double voteTotal = (voteData['total'] is num)
            ? (voteData['total'] as num).toDouble()
            : 0.0;
        totalScore += voteTotal;
        voteCount++;

        votesList.add({
          'judge': voteData['judge'] ?? 'Unknown Judge',
          'criteria': voteData['criteria_scores'] ?? {},
          'total': voteTotal,
        });
      }

      double averageScore = voteCount > 0 ? totalScore / voteCount : 0.0;
      candidateData.add({
        'contestant': contestant,
        'votes': votesList,
        'totalScore': totalScore,
        'voteCount': voteCount,
        'averageScore': averageScore,
      });
    }
    // Sort candidates in descending order by total score.
    candidateData.sort((a, b) =>
        (b['totalScore'] as double).compareTo(a['totalScore'] as double));
    return candidateData;
  }

  /// Fetch a mapping of criteria from the event document.
  /// The event document is expected to store criteria as a list of maps,
  /// each containing keys "name" and "weight".
  Future<Map<String, double>> fetchEventCriteriaMapping() async {
    DocumentSnapshot eventDoc = await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .get();
    Map<String, double> criteriaMap = {};
    var critData = eventDoc.get('criteria');
    if (critData is List<dynamic>) {
      for (var item in critData) {
        if (item is Map) {
          String name = item["name"]?.toString() ?? "";
          double weight = double.tryParse(item["weight"]?.toString() ?? "0") ?? 0;
          if (name.isNotEmpty) {
            criteriaMap[name] = weight;
          }
        }
      }
    }
    return criteriaMap;
  }

  /// Fetches the event name from the event document.
  Future<String> fetchEventName() async {
    DocumentSnapshot eventDoc = await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .get();
    String eventName = "Unknown Event";
    if (eventDoc.exists) {
      var data = eventDoc.data() as Map<String, dynamic>;
      eventName = data["name"] ?? "Unknown Event";
    }
    return eventName;
  }

  /// Combines candidate data, criteria mapping, and event name.
  Future<Map<String, dynamic>> fetchCombinedData() async {
    final candidates = await fetchCandidatesData();
    final criteriaMap = await fetchEventCriteriaMapping();
    final eventName = await fetchEventName();
    return {
      "candidates": candidates,
      "criteriaMap": criteriaMap,
      "eventName": eventName,
    };
  }

  /// Helper to clean up a criteria header.
  /// This function returns only the name portion of a raw criterion.
  String cleanupCriterionHeader(dynamic rawCrit) {
    if (rawCrit is Map) {
      return rawCrit["name"]?.toString() ?? "";
    }
    return rawCrit.toString();
  }

  /// Generates a PDF document that includes:
  /// • A header with the Event Name.
  /// • Detailed tables for each candidate.
  /// • A final aggregated results table.
  Future<Uint8List> _generatePdf(
      List<Map<String, dynamic>> candidates,
      Map<String, double> criteriaMap,
      String eventName) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
          List<pw.Widget> content = [];

          // PDF Header: Display event name.
          content.add(
            pw.Text("Event: $eventName",
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          );
          content.add(pw.SizedBox(height: 8));

          // Main report header.
          content.add(
            pw.Text("Detailed Candidate Vote Report",
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          );
          content.add(pw.SizedBox(height: 16));

          // Detailed tables for each candidate.
          for (var candidate in candidates) {
            final name = candidate['contestant'];
            final votes =
                (candidate['votes'] as List).cast<Map<String, dynamic>>();
            content.add(
              pw.Text("$name Vote Details",
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            );
            content.add(pw.SizedBox(height: 8));

            if (votes.isEmpty) {
              content.add(
                pw.Text("No votes submitted",
                    style: pw.TextStyle(color: PdfColor.fromInt(0xFFFF0000))),
              );
            } else {
              // Retrieve criteria keys from the first vote.
              List<dynamic> rawCriteriaKeys = [];
              if (votes.isNotEmpty &&
                  (votes.first['criteria'] as Map).isNotEmpty) {
                rawCriteriaKeys = (votes.first['criteria'] as Map).keys.toList();
              }
              List<String> criteriaKeys =
                  rawCriteriaKeys.map((raw) => cleanupCriterionHeader(raw)).toList();

              // Build table data.
              List<List<String>> tableData = [];
              // Header row: "Judge" followed by criteria names only, then "Total".
              List<String> headerRow = ["Judge"];
              headerRow.addAll(criteriaKeys);
              headerRow.add("Total");
              tableData.add(headerRow);

              // Data rows.
              for (var vote in votes) {
                List<String> row = [];
                row.add(vote['judge'].toString());
                Map<String, dynamic> critValues = vote['criteria'] as Map<String, dynamic>;
                for (var rawKey in rawCriteriaKeys) {
                  String keyStr = cleanupCriterionHeader(rawKey);
                  row.add(critValues.containsKey(keyStr) ? critValues[keyStr].toString() : "-");
                }
                row.add((vote['total'] as num).toStringAsFixed(1));
                tableData.add(row);
              }

              content.add(
                pw.Table.fromTextArray(
                  data: tableData,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFE0E0E0)),
                  cellHeight: 30,
                  cellAlignment: pw.Alignment.centerLeft,
                ),
              );
            }
            content.add(pw.SizedBox(height: 16));
          }

          // Final aggregated results table.
          content.add(
            pw.Text("Aggregated Scores & Rankings",
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          );
          content.add(pw.SizedBox(height: 8));
          List<List<String>> aggTable = [];
          aggTable.add([
            'Rank',
            'Contestant',
            'Total Score',
            'Votes',
            'Avg Score'
          ]);

          for (int i = 0; i < candidates.length; i++) {
            final candidate = candidates[i];
            String rank;
            if (i == 0)
              rank = "🥇 1st";
            else if (i == 1)
              rank = "🥈 2nd";
            else if (i == 2)
              rank = "🥉 3rd";
            else
              rank = "${i + 1}th";
            aggTable.add([
              rank,
              candidate['contestant'],
              (candidate['totalScore'] as double).toStringAsFixed(1),
              candidate['voteCount'].toString(),
              (candidate['averageScore'] as double).toStringAsFixed(1),
            ]);
          }

          content.add(
            pw.Table.fromTextArray(
              data: aggTable,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFE0E0E0)),
              cellHeight: 30,
              cellAlignment: pw.Alignment.centerLeft,
            ),
          );

          return content;
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Final Scoreboard"),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchCombinedData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final candidates =
              snapshot.data!['candidates'] as List<Map<String, dynamic>>;
          final criteriaMap =
              snapshot.data!['criteriaMap'] as Map<String, double>;
          final eventName = snapshot.data!['eventName'] as String;
          if (candidates.isEmpty) {
            return Center(child: Text("No votes submitted"));
          }
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display Event Name on screen
                Text("Event: $eventName",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                // Display each candidate's vote details in a Card.
                ...candidates.map((candidate) {
                  final votes =
                      (candidate['votes'] as List).cast<Map<String, dynamic>>();
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 3,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${candidate['contestant']} Vote Details",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          votes.isEmpty
                              ? Text("No votes submitted",
                                  style: TextStyle(color: Colors.red))
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: [
                                      DataColumn(
                                          label: Text("Judge",
                                              style: TextStyle(fontWeight: FontWeight.bold))),
                                      ...((votes.isNotEmpty &&
                                              (votes.first['criteria'] as Map).isNotEmpty)
                                          ? (votes.first['criteria'] as Map)
                                              .keys
                                              .map((rawKey) {
                                              String headerText = cleanupCriterionHeader(rawKey);
                                              return DataColumn(
                                                  label: Text(headerText,
                                                      style: TextStyle(fontWeight: FontWeight.bold)));
                                            }).toList()
                                          : []),
                                      DataColumn(
                                          label: Text("Total",
                                              style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: votes.map((vote) {
                                      Map<String, dynamic> crit =
                                          vote['criteria'] as Map<String, dynamic>;
                                      List<DataCell> cells = [];
                                      cells.add(DataCell(Text(vote['judge'].toString())));
                                      if (crit.isNotEmpty) {
                                        crit.forEach((key, value) {
                                          cells.add(DataCell(Text(value.toString())));
                                        });
                                      }
                                      cells.add(DataCell(Text(
                                          (vote['total'] as num).toStringAsFixed(1))));
                                      return DataRow(cells: cells);
                                    }).toList(),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                SizedBox(height: 16),
                // Aggregated Results Table.
                Text(
                  "Aggregated Scores & Rankings",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange),
                ),
                SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text("Rank", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Contestant", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Total Score", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Votes", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Avg Score", style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: List.generate(candidates.length, (index) {
                      final candidate = candidates[index];
                      String rankLabel;
                      if (index == 0)
                        rankLabel = "🥇 1st";
                      else if (index == 1)
                        rankLabel = "🥈 2nd";
                      else if (index == 2)
                        rankLabel = "🥉 3rd";
                      else
                        rankLabel = "${index + 1}th";
                      return DataRow(cells: [
                        DataCell(Text(rankLabel)),
                        DataCell(Text(candidate['contestant'])),
                        DataCell(Text((candidate['totalScore'] as double).toStringAsFixed(1))),
                        DataCell(Text(candidate['voteCount'].toString())),
                        DataCell(Text((candidate['averageScore'] as double).toStringAsFixed(1))),
                      ]);
                    }),
                  ),
                ),
                SizedBox(height: 16),
                // Print and Download Buttons.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        Uint8List pdfBytes = await _generatePdf(candidates, criteriaMap, eventName);
                        await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
                      },
                      child: Text("Print"),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        Uint8List pdfBytes = await _generatePdf(candidates, criteriaMap, eventName);
                        await Printing.sharePdf(bytes: pdfBytes, filename: 'score_results.pdf');
                      },
                      child: Text("Download"),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
