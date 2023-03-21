defmodule PmLogin.Utilities do
  use Phoenix.HTML
  import PmLoginWeb.Gettext

  def test do
    now = NaiveDateTime.local_now
    Calendar.strftime(now, "%d/%m/%Y %Hh %M")
  end

  def simple_date_format(naive_dt) do
    Calendar.strftime(naive_dt, "%d/%m/%Y")
  end

  def simple_date_format_with_hours(naive_dt) do
    Calendar.strftime(naive_dt, "%d/%m/%Y, à %Hh %M")
  end

  def simple_date_format_with_hours_onboard(naive_dt) do
    Calendar.strftime(naive_dt, "%d/%m/%Y, %Hh %M")
  end

  def letters_date_format_with_hours(naive_dt) do

    Calendar.strftime(naive_dt,"%A %d %B %Y, %Hh %M",
       day_of_week_names: fn day_of_week ->
         {"Lundi", "Mardi", "Mercredi", "Jeudi",
         "Vendredi", "Samedi", "Dimanche"}
         |> elem(day_of_week - 1)
       end,
       month_names: fn month ->
         {"Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
         "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"}
         |> elem(month - 1)
       end
      )
  end

  def letters_date_format_with_only_month_and_hours(naive_dt) do

    Calendar.strftime(naive_dt,"%d %B %Y, %Hh %M",
       month_names: fn month ->
         {"Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
         "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"}
         |> elem(month - 1)
       end
      )
  end

  def my_datetime_select(form, field, opts \\ []) do

    now = NaiveDateTime.local_now()

    builder = fn b ->
      ~e"""
      <%= b.(:day, []) %><%= b.(:month, []) %><%= b.(:year, []) %>
      <%= b.(:hour, []) %> h : <%= b.(:minute, []) %> min
      """
    end

    day = [selected: now.day]

    month = [
      options: [
        {gettext("Janvier"), "1"},
        {gettext("Février"), "2"},
        {gettext("Mars"), "3"},
        {gettext("Avril"), "4"},
        {gettext("Mai"), "5"},
        {gettext("Juin"), "6"},
        {gettext("Juillet"), "7"},
        {gettext("Août"), "8"},
        {gettext("Septembre"), "9"},
        {gettext("Octobre"), "10"},
        {gettext("Novembre"), "11"},
        {gettext("Décembre"), "12"},
      ],
      selected: now.month
    ]

    year = [options: (now.year)..(now.year+10)]

    hour = [selected: now.hour]

    datetime_select(form, field, [builder: builder] ++ [month: month] ++ [year: year] ++ [day: day] ++ [hour: hour] ++ opts)
  end

  def letters_date_format(naive_dt) do

    Calendar.strftime(naive_dt,"%A %d %B %Y",
       day_of_week_names: fn day_of_week ->
         {"Lundi", "Mardi", "Mercredi", "Jeudi",
         "Vendredi", "Samedi", "Dimanche"}
         |> elem(day_of_week - 1)
       end,
       month_names: fn month ->
         {"Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
         "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"}
         |> elem(month - 1)
       end
      )
  end

  def letters_date_format_without_days(naive_dt) do

    Calendar.strftime(naive_dt,"%d %B %Y",
       month_names: fn month ->
         {"Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
         "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"}
         |> elem(month - 1)
       end
      )
  end

  def naive_to_datetime(naive) do
    {:ok, datetime} = DateTime.from_naive(naive, "Etc/UTC")
    datetime
  end

  def date_to_naive(date) do
    {:ok, naive} = {Date.to_erl(date),{0,0,0}} |> NaiveDateTime.from_erl
    naive
  end

  def date_to_datetime(date) do
    {:ok, naive} = {Date.to_erl(date),{0,0,0}} |> NaiveDateTime.from_erl
    naive_to_datetime(naive)
  end

  # def seconds_between_dates(dt1, dt2) do

  # end
  def days_to_seconds(days) do
    days * 86400
  end

  #PERIODIC TEST
  def next_end(start_date, days_period) do

    # IO.puts("Start date: #{start_date} | Period: #{days_period}")
    curr_next_end = NaiveDateTime.add(start_date, days_to_seconds(days_period))

    now = NaiveDateTime.local_now()

    # IO.puts("End : #{curr_next_end}")

    cond do

      NaiveDateTime.compare(now, start_date) == :lt -> start_date
      (NaiveDateTime.compare(now, start_date) == :gt or NaiveDateTime.compare(now, start_date) == :eq) and (NaiveDateTime.compare(now, curr_next_end) == :lt) -> curr_next_end
      NaiveDateTime.compare(now, curr_next_end) == :gt or NaiveDateTime.compare(now, curr_next_end) == :eq -> next_end(curr_next_end, days_period)

    end

  end

  def test_next_end(start_date, period, val) do

    curr_next_end = start_date + period
    IO.puts("Start date: #{start_date} | Period: #{period}")
    IO.puts("End : #{curr_next_end}")

    cond do
      start_date < val and val <= curr_next_end ->
        curr_next_end

      curr_next_end < val ->
        test_next_end(curr_next_end, period, val)
    end

  end

end
