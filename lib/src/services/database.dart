import "service.dart";

/// A database that can read and write data. 
/// 
/// A [Database] is a special type of [Service]. Whereas a service only needs
/// to know when the app starts and the user signs in, a database has other 
/// responsibilities. 
/// 
/// Functionally, a database needs to be able to determine whether the user
/// is signed in, so the app knows where to direct the user. Additionally,
/// since the data is tied to the user, the database needs to know when the
/// user is signing out, it can purge that data. Of course, the database also
/// needs to know when the user is signing in, so it can connect to the data. 
/// 
/// This class also serves to dictate what data the database should provide, 
/// as well as their types. Most of the code in this class does exactly that. 
abstract class Database extends Service {
	/// The key to get the calendar within the returned JSON object. 
	/// 
	/// The calendar is stored along with its month, which means it cannot
	/// be a list, and instead must be a `Map<String, dynamic>`. This key
	/// gets the list out of the Map. 
	static const String calendarKey = "calendar";

	/// Determines whether the user is signed in.
	/// 
	/// From all the services, a [Database] is the only one that can, and is 
	/// expected to, know whether the user is signed in. The implementation 
	/// is up to the database itself, but it's allowed to be asynchronous.  
	Future<bool> get isSignedIn;

	/// Signs the user out of the app. 
	/// 
	/// As opposed to [signIn], only databases need to know when the user is
	/// signing out. It can be helpful for non-database services to know when the 
	/// user signs in, since this indicates they are truly ready to engage with 
	/// the app, but signing out carries no valuable information. The databases,
	/// however, must purge all their data. 
	Future<void> signOut();

	// ---------- Data code below ---------- 

	/// The user object as JSON
	Future<Map<String, dynamic>> get user;

	/// Changes the user JSON object. 
	Future<void> setUser(Map<String, dynamic> json);

	/// Gets one section (a course in Ramaz) as a JSON object. 
	/// 
	/// Do not use this directly. Instead, use [getSections]. 
	Future<Map<String, dynamic>> getSection(String id);

	/// The different classes (sections, not courses) for a schedule.
	Future<Map<String, Map<String, dynamic>>> getSections(
		Iterable<String> ids
	) async => {
		for (final String id in ids)
			id: await getSection(id)
	};

	/// Changes the user's classes.
	Future<void> setSections(Map<String, Map<String, dynamic>> json);

	/// The calendar in JSON form. 
	/// 
	/// Admins can change this with [setCalendar]. 
	Future<List<List<Map<String, dynamic>>>> get calendar async => [
		for (int month = 1; month <= 12; month++) [
			for (final dynamic day in (await getCalendarMonth(month)) [calendarKey])
				Map<String, dynamic>.from(day)
		]
	];

	/// Gets one month out of the calendar. 
	/// 
	/// Months are in the range 1-12. The value returned will be a JSON object 
	/// containing the month and the calendar. The calendar itself can be retrieved
	/// with [calendarKey].
	Future<Map<String, dynamic>> getCalendarMonth(int month);

	/// Changes the calendar in the database. 
	/// 
	/// The fact that this method takes a [month] parameter while [calendar] does
	/// not is an indicator that the calendar schema needs to be rewritten. 
	/// 
	/// [month] must be 1-12, not 0-11. 
	/// 
	/// Only admins can change this. 
	Future<void> setCalendar(int month, Map<String, dynamic> json);

	/// The user's reminders. 
	Future<List<Map<String, dynamic>>> get reminders;

	/// Sets the user's reminders. 
	Future<void> setReminders(List<Map<String, dynamic>> json);

	/// The admin object (or null).
	Future<Map<String, dynamic>> get admin;

	/// Sets the admin object for this user.
	Future<void> setAdmin(Map<String, dynamic> json);

	/// The sports games. 
	/// 
	/// Admins can change this with [setSports]. 
	Future<List<Map<String, dynamic>>> get sports;

	/// Sets the sports games.
	/// 
	/// Only admins can change this. 
	Future<void> setSports(List<Map<String, dynamic>> json);
}