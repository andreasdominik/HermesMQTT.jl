


"""
    function readable_date_time(datetime::AbstractString; lang=get_language())
                              wholeDay = false, onlyDay = false)
    function readable_date_time(datetime::DateTime; lang=get_language(),
                              wholeDay = false, onlyDay = false)
    function readable_date(datetime::Date; lang=get_language())

Return human readable date and time, like
"Friday, 1. January 2018",  "9 15"

Supported languages: "en", "de", "fr".

## Arguments:
* datetime: date and optional time as ISO string or as DateTime object.
* lang: Language code (e.g. "en" or "de")
* wholeDay: boolean, if true, no time is returned, instead "whole day"
* onlyDay: just tell the day, not the time
* onlyTime: just tell the time, not the day

## Value:
String value with readable date and time.
"""
function readable_date_time(datetime::AbstractString; lang=get_language(),
                          wholeDay=false, onlyDay=false, onlyTime=false)

    # remove time zone and make DateTime object:
    #
    datetime = replace(datetime, r"\+.*$" => "")
    d = DateTime(datetime)

    # check, if a time is in the string:
    #
    if !occursin("T", datetime)
        wholeDay = true
    end

    # make date String:
    #
    return readable_date_time(d, lang=lang,
                            wholeDay=wholeDay, onlyDay=onlyDay, onlyTime=onlyTime)
end


function readable_date(datetime::Date; lang=get_language())

    return readable_date_time(Dates.DateTime(datetime), lang=lang,
                            wholeDay=false, onlyDay=true)
end


function readable_date_time(datetime::DateTime; lang=get_language(),
            wholeDay = false, onlyDay = false, onlyTime = false)

    # set locale:
    #
    if lang == "en"
        locale = "english"
    elseif lang == "de"
        locale = "german"
    elseif lang == "fr"
        locale = "french"
    else
        locale = "english"
    end

    # Make locales for German and French:
    #
    french_months = ["janvier", "février", "mars", "avril", "mai", "juin",
                     "juillet", "août", "septembre", "octobre",
                     "novembre", "décembre"];

    french_monts_abbrev = ["janv","févr","mars","avril","mai","juin",
                           "juil","août","sept","oct","nov","déc"];

    french_days = ["lundi","mardi","mercredi","jeudi","vendredi",
                   "samedi","dimanche"];

    french_days_abbrev = ["lu","ma","me","je","ve", "sa","di"];

    Dates.LOCALES["french"] = Dates.DateLocale(french_months, french_monts_abbrev,
                                               french_days, french_days_abbrev);


    german_months = ["Januar", "Februar", "März", "April", "Mai", "Juni",
                     "Juli", "August", "September", "Oktober",
                     "November", "Dezember"];

    german_monts_abbrev = ["Jan","Feb","Mär","Apr","Mai","Jun",
                           "Jul","Aug","Sept","Okt","Nov","Dez"];

    german_days = ["Montag","Dienstag","Mittwoch","Donnerstag","Freitag",
                   "Samstag","Sonntag"];

    german_days_abbrev = ["Mo","Di","Mi","Do","Fr", "Sa","So"];

    Dates.LOCALES["german"] = Dates.DateLocale(german_months, german_monts_abbrev,
                                               german_days, german_days_abbrev);

    if onlyTime
        textDate = ""
    else
        dname = Dates.dayname(datetime, locale = locale)
        d =  Dates.dayofmonth(datetime)
        mname = Dates.monthname(datetime, locale = locale)
        y =  Dates.year(datetime)
        textDate = "$dname, $d. $mname $y"
    end

    if onlyDay
        textTime = ""
    elseif wholeDay
        if locale == "german"
            textTime = "den ganzen Tag"
        elseif locale == "french"
            textTime = "toute la journée"
        else
            textTime = "whole day"
        end
    else
        h = Dates.hour(datetime)
        m = Dates.minute(datetime)

        if locale == "german"
            textTime = "$h Uhr $m"
        elseif locale == "french"
            textTime = "$h heures et $m minutes"
        else
            if m == 0
                textTime = """$h o'clock"""
            else
                textTime = "$h:$m"
            end
        end
    end

    return "$textDate, $textTime"
end
