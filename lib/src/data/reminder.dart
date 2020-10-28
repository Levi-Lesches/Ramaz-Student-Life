/// This library handles serialization and deserialization of reminders. 
/// 
/// Each reminder has a [Reminder.time] property, which is a [ReminderTime],
/// describing when said reminder should be displayed. Since reminders could
/// be shown on a specific class or period, the classes [PeriodReminderTime]
/// and [SubjectReminderTime] are used. 
library reminder_dataclasses;

import "dart:convert" show JsonUnsupportedObjectError;
import "package:meta/meta.dart";

/// An enum to decide when the reminder should appear. 
/// 
/// `period` means the reminder needs a Day name and a period (as [String])
/// `subject` means the reminder needs a name of a class.
enum ReminderTimeType {
	/// Whether the reminder should be displayed on a specific period.
	period, 

	/// Whether the reminder should be displayed on a specific subject.
	subject
}

/// Used to convert [ReminderTimeType] to JSON.
const Map<ReminderTimeType, String> reminderTimeToString = {
	ReminderTimeType.period: "period",
	ReminderTimeType.subject: "subject",
};

/// Used to convert JSON to [ReminderTimeType].
const Map<String, ReminderTimeType> stringToReminderTime = {
	"period": ReminderTimeType.period,
	"subject": ReminderTimeType.subject,
};

/// A time that a reminder should show.
/// 
/// Should be used for [Reminder.time].
@immutable
abstract class ReminderTime {
	/// The type of reminder. 
	/// 
	/// This field is here for other objects to use. 
	final ReminderTimeType type;

	/// Whether the reminder should repeat.
	final bool repeats;

	/// Allows its subclasses to be `const`. 
	const ReminderTime({
		@required this.repeats, 
		@required this.type
	});

	/// Initializes a new instance from JSON.
	/// 
	/// Mainly looks at `json ["type"]` to choose which type of 
	/// [ReminderTime] it should instantiate, and then leaves the 
	/// work to that subclass' `.fromJson` method. 
	/// 
	/// Example JSON: 
	/// ```
	/// {
	/// 	"type": "period",
	/// 	"repeats": false,
	/// 	"period": "9",
	/// 	"name": "Monday",
	/// }
	/// ```
	factory ReminderTime.fromJson(Map<String, dynamic> json) {
		switch (stringToReminderTime [json ["type"]]) {
			case ReminderTimeType.period: return PeriodReminderTime.fromJson(json);
			case ReminderTimeType.subject: return SubjectReminderTime.fromJson(json);
			default: throw JsonUnsupportedObjectError(
				json,
				cause: "Invalid time for reminder: $json"
			);
		}
	}

	/// Instantiates new [ReminderTime] with all possible parameters. 
	/// 
	/// Used for cases where the caller doesn't care about the [ReminderTimeType],
	/// such as a UI reminder builder. 
	factory ReminderTime.fromType({
		@required ReminderTimeType type,
		@required String dayName,
		@required String period,
		@required String name,
		@required bool repeats,
	}) {
		switch (type) {
			case ReminderTimeType.period: return PeriodReminderTime(
				period: period,
				dayName: dayName,
				repeats: repeats,
			); case ReminderTimeType.subject: return SubjectReminderTime(
				name: name,
				repeats: repeats,
			); default: throw ArgumentError.notNull("type");
		}
	}

	/// Returns this [ReminderTime] as JSON.
	Map<String, dynamic> toJson();

	/// Checks if the [Reminder] should be displayed.
	/// 
	/// All possible parameters are required. 
	bool doesApply({
		@required String dayName, 
		@required String subject, 
		@required String period,
	});

	/// Returns a String representation of this [ReminderTime].
	///
	/// Used for debugging and throughout the UI.
	@override
	String toString();
}

/// A [ReminderTime] that depends on a name and period.
@immutable
class PeriodReminderTime extends ReminderTime {
	/// The day for when this [Reminder] should be displayed.
	final String dayName;

	/// The period when this [Reminder] should be displayed.
	final String period;

	/// Returns a new [PeriodReminderTime].
	/// 
	/// All parameters must be non-null.
	const PeriodReminderTime({
		@required this.dayName,
		@required this.period,
		@required bool repeats
	}) : super (repeats: repeats, type: ReminderTimeType.period);

	/// Creates a new [ReminderTime] from JSON.
	/// 
	/// `json ["dayName"]` should be one of the valid names.
	/// 
	/// `json ["period"]` should be a valid period for that day,
	/// notwithstanding any schedule changes (like an "early dismissal").
	PeriodReminderTime.fromJson(Map<String, dynamic> json) :
		dayName = json ["dayName"],
		period = json ["period"],
		super (repeats: json ["repeats"], type: ReminderTimeType.period);

	@override
	String toString() => 
		"${repeats ? 'Repeats every ' : ''}$dayName-$period";

	@override 
	Map<String, dynamic> toJson() => {
		"name": dayName,
		"period": period,
		"repeats": repeats,
		"type": reminderTimeToString [type],
	};

	/// Returns true if [dayName] and [period] match this instance's fields.
	@override
	bool doesApply({
		@required String dayName, 
		@required String subject, 
		@required String period,
	}) => dayName == this.dayName && period == this.period;
}

/// A [ReminderTime] that depends on a subject. 
@immutable
class SubjectReminderTime extends ReminderTime {
	/// The name of the subject this [ReminderTime] depends on.
	final String name;

	/// Returns a new [SubjectReminderTime]. All parameters must be non-null.
	const SubjectReminderTime({
		@required this.name,
		@required bool repeats,
	}) : super (repeats: repeats, type: ReminderTimeType.subject);

	/// Returns a new [SubjectReminderTime] from a JSON object.
	/// 
	/// The fields `repeats` and `name` must not be null.
	SubjectReminderTime.fromJson(Map<String, dynamic> json) :
		name = json ["name"],
		super (repeats: json ["repeats"], type: ReminderTimeType.subject);

	@override
	String toString() => (repeats ? "Repeats every " : "") + name;

	@override 
	Map<String, dynamic> toJson() => {
		"name": name,
		"repeats": repeats,
		"type": reminderTimeToString [type],
	};

	/// Returns true if this instance's [subject] field 
	/// matches the `subject` parameter.
	@override
	bool doesApply({
		@required String dayName, 
		@required String subject, 
		@required String period,
	}) => subject == name;
}

/// A user-generated reminder.
@immutable
class Reminder {
	/// Returns all reminders from a list of reminders that should be shown. 
	/// 
	/// All possible parameters are required. 
	/// This function delegates logic to [ReminderTime.doesApply]
	static List<int> getReminders({
		@required List<Reminder> reminders,
		@required String dayName,
		@required String period,
		@required String subject,
	}) => [
		for (int index = 0; index < reminders.length; index++)
			if (reminders [index].time.doesApply(
				dayName: dayName,
				period: period,
				subject: subject				
			)) index
	];

	/// Returns a list of reminders from a list of JSON objects. 
	/// 
	/// Calls [Reminder.fromJson] for every JSON object in the list.
	static List<Reminder> fromList(List reminders) => [
		for (final dynamic json in reminders)
			Reminder.fromJson(Map<String, dynamic>.from(json))
	];

	/// The message this reminder should show. 
	final String message;

	/// The [ReminderTime] for this reminder. 
	final ReminderTime time;

	/// Creates a new reminder.
	const Reminder({
		@required this.message,
		this.time,
	});

	/// Creates a new [Reminder] from a JSON object.
	/// 
	/// Uses `json ["message"]` for the message and passes `json["time"]` 
	/// to [ReminderTime.fromJson]
	Reminder.fromJson(dynamic json) :
		message = json ["message"],
		time = ReminderTime.fromJson(Map<String, dynamic>.from(json ["time"]));

	@override String toString() => "$message ($time)";

	/// Returns a JSON representation of this reminder.
	Map<String, dynamic> toJson() => {
		"message": message,
		"time": time.toJson(),
	};
}
