import "package:flutter/foundation.dart";

import "package:ramaz/data.dart";
import "package:ramaz/models.dart";
import "package:ramaz/services.dart" hide AsyncCallback;

/// Different ways to sort the sports calendar.
enum SortOption {
	/// Sorts the sports games chronologically.
	/// 
	/// Uses [SportsGame.date].
	chronological, 

	/// Sorts the sports game by sport. 
	/// 
	/// Uses [SportsGame.sport].
	sport
}


/// A view model for the sports page. 
/// 
/// This class provides sorting methods for the games ([sortGames]) as well as 
/// helpful properties for the admin version of this page ([isAdmin] and 
/// [loading]).
// ignore: prefer_mixin
class SportsModel with ChangeNotifier {
	/// The data model behind this view model.
	final Sports data;

	/// A list of recent games.
	List<int> recents = [];

	/// A list of upcoming games.
	List<int> upcoming = [];

	/// Recent games sorted by sport.
	/// 
	/// Generated by calling [sortBySport] with [recents]. 
	Map<Sport, List<int>> recentBySport = {};

	/// Upcoming games sorted by sport. 
	/// 
	/// Generated by calling [sortBySport] with [upcoming].
	Map<Sport, List<int>> upcomingBySport = {};

	/// Whether the user is an admin. 
	/// 
	/// This will allow widgets to give the user options to change some entries.
	bool isAdmin = false;

	SortOption _sortOption = SortOption.chronological;
	bool _loading = false;

	/// Creates a view model for the sports page. 
	SportsModel(this.data) {
		Auth.isSportsAdmin.then(
			(bool value) {
				isAdmin = value;
				notifyListeners();
			}
		);
		data.addListener(setup);
		setup();
	}

	@override
	void dispose() {
		data.removeListener(setup);
		super.dispose();
	}

	/// The currently selected sorting option.
	SortOption get sortOption => _sortOption;
	set sortOption(SortOption value) {
		_sortOption = value;
		sortGames();
		notifyListeners();
	}

	/// Whether the page is loading. 
	bool get loading => _loading;
	set loading(bool value) {
		_loading = value;
		notifyListeners();
	}

	/// Gathers data from [data] and prepares the page for building.
	void setup() {
		divideGames();
		sortGames();
		notifyListeners();
	}

	/// Helper function to sort games chronologically.
	/// 
	/// See [Comparator] and [Comparable.compareTo] for how to sort in Dart. 
	int sortByDate(int a, int b) => 
		data.games [a].dateTime.compareTo(data.games [b].dateTime);

	/// Divides [Sports.games] into [recents] and [upcoming].
	void divideGames() {
		recents = [];
		upcoming = [];
		final DateTime now = DateTime.now();
		for (final MapEntry<int, SportsGame> entry in data.games.asMap().entries) {
			(entry.value.dateTime.isAfter(now) ? upcoming : recents).add(entry.key);
		}
		recents.sort(sortByDate);
		upcoming.sort(sortByDate);
	}

	/// Sorts a list of games by sports. 
	/// 
	/// The resulting map has all the sports as keys, and a list of games with 
	/// that sport as its values.
	Map<Sport, List<int>> sortBySport(List<int> gamesList) {
		final Map<Sport, List<int>> result = {};
		for (final int index in gamesList) {
			final SportsGame game = data.games [index];
			if (!result.containsKey(game.sport)) {
				result [game.sport] = [index];
			} else {
				result [game.sport]!.add(index);
			}
		}
		for (final List<int> gamesList in result.values) {
			gamesList.sort(sortByDate);  // sort chronologically in place
		}
		return result;
	}

	/// Sorts the page according to [sortOption].
	/// 
	/// By the time this function is called, [recents] and [upcoming] are already
	/// sorted chronologically, so if [sortOption] equals 
	/// [SortOption.chronological], nothing happens. 
	void sortGames() {
		switch (sortOption) {
			case SortOption.chronological: break;  // already sorted
			case SortOption.sport: 
				recentBySport = sortBySport(recents);
				upcomingBySport = sortBySport(upcoming);
		}
	}

	/// Refreshes the sports data needed for the sports page.
	Future<void> refresh() async {
		await Services.instance.database.sports.signIn();
		await Models.instance.sports.init();
		setup();
	}
}
