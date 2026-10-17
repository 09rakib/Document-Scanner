import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';

/// Used only inside compute. Buffer small writes and stream the finished PDF to
/// disk instead of retaining all JPEGs and a second complete PDF in memory.
class FilePdfStream extends PdfStream {
  FilePdfStream(File file) : _file = file.openSync(mode: FileMode.write);
  final RandomAccessFile _file;
  final _buffer = Uint8List(64 * 1024);
  int _used = 0;
  int _position = 0;
  @override
  int get offset => _position;
  @override
  void putByte(int s) {
    if (_used == _buffer.length) _flush();
    _buffer[_used++] = s;
    _position++;
  }

  @override
  void putBytes(List<int> s) {
    var start = 0;
    while (start < s.length) {
      if (_used == _buffer.length) _flush();
      final remaining = s.length - start;
      final capacity = _buffer.length - _used;
      final count = remaining < capacity ? remaining : capacity;
      _buffer.setRange(_used, _used + count, s, start);
      start += count;
      _used += count;
      _position += count;
    }
  }

  @override
  void putStream(PdfStream s) => putBytes(s.output());
  @override
  void setBytes(int offset, Iterable<int> iterable) {
    _flush();
    _file.setPositionSync(offset);
    _file.writeFromSync(iterable.toList());
    _file.setPositionSync(_position);
  }

  @override
  Uint8List output() => throw UnsupportedError('File-backed PDF output');
  void _flush() {
    if (_used == 0) return;
    _file.writeFromSync(_buffer, 0, _used);
    _used = 0;
  }

  void close() {
    try {
      _flush();
      _file.flushSync();
    } finally {
      _file.closeSync();
    }
  }
}
