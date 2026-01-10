/// Enum-based state machine for search operations
enum SearchState {
  /// App is idle, not searching
  idle,
  
  /// Actively searching for coverage
  searching,
  
  /// Coverage has been found
  coverageFound,
  
  /// Search is paused
  paused,
}

extension SearchStateExtension on SearchState {
  /// Returns a user-friendly description of the state
  String get description {
    switch (this) {
      case SearchState.idle:
        return 'Klar til å søke';
      case SearchState.searching:
        return 'Søker etter dekning...';
      case SearchState.coverageFound:
        return 'Dekning funnet!';
      case SearchState.paused:
        return 'Søking pauset';
    }
  }

  /// Returns whether the state represents an active search
  bool get isActive => this == SearchState.searching || this == SearchState.coverageFound;
  
  /// Returns whether the state allows starting a new search
  bool get canStart => this == SearchState.idle;
  
  /// Returns whether the state allows stopping
  bool get canStop => this != SearchState.idle;
  
  /// Returns whether the state allows pausing
  bool get canPause => this == SearchState.coverageFound || this == SearchState.searching;
}
