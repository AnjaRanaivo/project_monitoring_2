defmodule PmLogin.MyContex do
  # import Ecto.Changeset
  import Ecto.Query, warn: false
  # alias PmLogin.Repo
  alias PmLogin.Monitoring
  alias PmLogin.Monitoring.Task

  def todays_dataset do
    todays = Monitoring.list_achieved_tasks_today
    default_date = NaiveDateTime.local_now() |> NaiveDateTime.add(-864000)
    default_data = [%Task{priority_id: 1, title: "Faible", date_start: default_date,achieved_at: date_to_naive(default_date)},
    %Task{priority_id: 2, title: "Moyenne", date_start: default_date, achieved_at: date_to_naive(default_date)},
    %Task{priority_id: 3, title: "Importante", date_start: default_date, achieved_at: date_to_naive(default_date)},
    %Task{priority_id: 4, title: "Urgente", date_start: default_date,achieved_at: date_to_naive(default_date)}
  ]
    # default_data = [["","",NaiveDateTime.utc_now(),NaiveDateTime.utc_now()],["","",NaiveDateTime.utc_now(),NaiveDateTime.utc_now()],["","",NaiveDateTime.utc_now(),NaiveDateTime.utc_now()],["","",NaiveDateTime.utc_now(),NaiveDateTime.utc_now()]]
    # IO.inspect todays
    IO.puts length(todays)
    case length(todays) do
      0 -> "Aucune tâche accomplie ce jour"
        data = default_data
        |> Enum.map(fn(task) ->
          ["#{PmLogin.Monitoring.get_priority!(task.priority_id).title}", task.title, date_to_naive(task.date_start), task.achieved_at]
        end)
        |> Enum.reverse


      # IO.inspect data
        dataset = Contex.Dataset.new(data, ["Cat", "Task", "Start", "End"])

        opts =
          [
            mapping:  %{category_col: "Cat", task_col: "Task", start_col: "Start", finish_col: "End"},
            colour_palette: ["ff0000", "f8961e", "4361ee", "90ee90"]
          ]

        # IO.inspect dataset
        colour_scale = dataset
                        |> Contex.Dataset.unique_values("Cat")
                        |> Contex.CategoryColourScale.new(["90ee90", "4361ee", "f8961e", "ff0000"])

        cs = %Contex.CategoryColourScale{
          colour_map: %{1 => "1f77b4", 2 => "2ca02c", 3 => "ff7f0e", 4 => "d62728"},
          colour_palette: ["1f77b4", "2ca02c", "ff7f0e", "d62728", "9467bd", "8c564b",
            "e377c2", "7f7f7f", "bcbd22", "17becf"],
          default_colour: nil,
          values: [1, 2, 3, 4]
        }


        plot_content = Contex.GanttChart.new(dataset, category_scale: colour_scale)

        cs_plot = struct(plot_content, category_scale: cs)
        # IO.inspect(Contex.CategoryColourScale.get_default_colour(cs))

        plot = Contex.Plot.new(dataset, Contex.GanttChart, 600, 450, opts)
          |> Contex.Plot.attributes(y_label: "Priorité", x_label: "Dates de début et d'achèvement des tâches")
          Contex.Plot.to_svg(plot)

      _ ->
        pre_data = todays ++ default_data
        data = Enum.sort_by(pre_data, fn(task) -> task.priority_id end)
        |> Enum.map(fn(task) ->
          ["#{PmLogin.Monitoring.get_priority!(task.priority_id).title}", task.title, date_to_naive(task.date_start), task.achieved_at]
        end)
        |> Enum.reverse

        # data = default_data ++ pre_data
      IO.puts "io ny data days"
      IO.inspect data
        dataset = Contex.Dataset.new(data, ["Cat", "Task", "Start", "End"])

        opts =
          [
            mapping:  %{category_col: "Cat", task_col: "Task", start_col: "Start", finish_col: "End"},
            colour_palette: ["ff0000", "f8961e", "4361ee", "90ee90"]
          ]

        # IO.inspect dataset
        colour_scale = dataset
                        |> Contex.Dataset.unique_values("Cat")
                        |> Contex.CategoryColourScale.new(["90ee90", "4361ee", "f8961e", "ff0000"])

        cs = %Contex.CategoryColourScale{
          colour_map: %{1 => "1f77b4", 2 => "2ca02c", 3 => "ff7f0e", 4 => "d62728"},
          colour_palette: ["1f77b4", "2ca02c", "ff7f0e", "d62728", "9467bd", "8c564b",
            "e377c2", "7f7f7f", "bcbd22", "17becf"],
          default_colour: nil,
          values: [1, 2, 3, 4]
        }


        plot_content = Contex.GanttChart.new(dataset, category_scale: colour_scale)

        cs_plot = struct(plot_content, category_scale: cs)
        # IO.inspect(Contex.CategoryColourScale.get_default_colour(cs))

        plot = Contex.Plot.new(dataset, Contex.GanttChart, 600, 450, opts)
          |> Contex.Plot.attributes(y_label: "Priorité", x_label: "Dates de début et d'achèvement des tâches")
          Contex.Plot.to_svg(plot)
    end

  end

  def this_week_dataset do
    this_weeks = Monitoring.list_achieved_tasks_this_week
    default_date = NaiveDateTime.local_now() |> NaiveDateTime.add(-864000)
    default_data = [%Task{priority_id: 1, title: "Faible", date_start: default_date,achieved_at: date_to_naive(default_date)},
    %Task{priority_id: 2, title: "Moyenne", date_start: default_date, achieved_at: date_to_naive(default_date)},
    %Task{priority_id: 3, title: "Importante", date_start: default_date, achieved_at: date_to_naive(default_date)},
    %Task{priority_id: 4, title: "Urgente", date_start: default_date,achieved_at: date_to_naive(default_date)}
  ]
    case length(this_weeks) do
      0 -> "Aucune tâche accomplie cette semaine"
        data = default_data
        |> Enum.map(fn(task) ->
          ["#{PmLogin.Monitoring.get_priority!(task.priority_id).title}", task.title, date_to_naive(task.date_start), task.achieved_at]
        end)
        |> Enum.reverse


      # IO.inspect data
        dataset = Contex.Dataset.new(data, ["Cat", "Task", "Start", "End"])

        opts =
          [
            mapping:  %{category_col: "Cat", task_col: "Task", start_col: "Start", finish_col: "End"},
            colour_palette: ["ff0000", "f8961e", "4361ee", "90ee90"]
          ]

        # IO.inspect dataset
        colour_scale = dataset
                        |> Contex.Dataset.unique_values("Cat")
                        |> Contex.CategoryColourScale.new(["90ee90", "4361ee", "f8961e", "ff0000"])

        cs = %Contex.CategoryColourScale{
          colour_map: %{1 => "1f77b4", 2 => "2ca02c", 3 => "ff7f0e", 4 => "d62728"},
          colour_palette: ["1f77b4", "2ca02c", "ff7f0e", "d62728", "9467bd", "8c564b",
            "e377c2", "7f7f7f", "bcbd22", "17becf"],
          default_colour: nil,
          values: [1, 2, 3, 4]
        }


        plot_content = Contex.GanttChart.new(dataset, category_scale: colour_scale)

        cs_plot = struct(plot_content, category_scale: cs)
        # IO.inspect(Contex.CategoryColourScale.get_default_colour(cs))

        plot = Contex.Plot.new(dataset, Contex.GanttChart, 600, 450, opts)
          |> Contex.Plot.attributes(y_label: "Priorité", x_label: "Dates de début et d'achèvement des tâches")
          Contex.Plot.to_svg(plot)

      _ ->
        # data = Enum.sort_by(this_weeks, fn(task) -> task.priority_id end)
        pre_data = this_weeks ++ default_data
        data = Enum.sort_by(pre_data, fn(task) -> task.priority_id end)
        |> Enum.map(fn(task) ->
          ["#{PmLogin.Monitoring.get_priority!(task.priority_id).title}", task.title, date_to_naive(task.date_start), task.achieved_at]
        end)
        |> Enum.reverse

      # IO.inspect data
        dataset = Contex.Dataset.new(data, ["Cat", "Task", "Start", "End"])

        opts =
          [
            mapping:  %{category_col: "Cat", task_col: "Task", start_col: "Start", finish_col: "End"},
            colour_palette: ["ff0000", "f8961e", "4361ee", "90ee90"]
          ]

        # IO.inspect dataset
        colour_scale = dataset
                        |> Contex.Dataset.unique_values("Cat")
                        |> Contex.CategoryColourScale.new(["90ee90", "4361ee", "f8961e", "ff0000"])

        cs = %Contex.CategoryColourScale{
          colour_map: %{1 => "1f77b4", 2 => "2ca02c", 3 => "ff7f0e", 4 => "d62728"},
          colour_palette: ["1f77b4", "2ca02c", "ff7f0e", "d62728", "9467bd", "8c564b",
            "e377c2", "7f7f7f", "bcbd22", "17becf"],
          default_colour: nil,
          values: [1, 2, 3, 4]
        }


        plot_content = Contex.GanttChart.new(dataset, category_scale: colour_scale)

        cs_plot = struct(plot_content, category_scale: cs)
        # IO.inspect(Contex.CategoryColourScale.get_default_colour(cs))

        plot = Contex.Plot.new(dataset, Contex.GanttChart, 600, 450, opts)
          |> Contex.Plot.attributes(y_label: "Priorité", x_label: "Dates de début et d'achèvement des tâches")
          Contex.Plot.to_svg(plot)
    end

  end

  @spec this_month_dataset :: {:safe, [...]}
  def this_month_dataset do
    this_months = Monitoring.list_achieved_tasks_this_month
    default_date = NaiveDateTime.local_now() |> NaiveDateTime.add(-864000)
    default_data = [%Task{priority_id: 1, title: "Faible", date_start: default_date,achieved_at: date_to_naive(default_date)},
    %Task{priority_id: 2, title: "Moyenne", date_start: default_date, achieved_at: date_to_naive(default_date)},
    %Task{priority_id: 3, title: "Importante", date_start: default_date, achieved_at: date_to_naive(default_date)},
    %Task{priority_id: 4, title: "Urgente", date_start: default_date,achieved_at: date_to_naive(default_date)}
  ]

    case length(this_months) do
      0 -> "Aucune tâche accomplie ce mois"
        data = default_data
          |> Enum.map(fn(task) ->
            ["#{PmLogin.Monitoring.get_priority!(task.priority_id).title}", task.title, date_to_naive(task.date_start), task.achieved_at]
          end)
          |> Enum.reverse


        # IO.inspect data
          dataset = Contex.Dataset.new(data, ["Cat", "Task", "Start", "End"])

          opts =
            [
              mapping:  %{category_col: "Cat", task_col: "Task", start_col: "Start", finish_col: "End"},
              colour_palette: ["ff0000", "f8961e", "4361ee", "90ee90"]
            ]

          # IO.inspect dataset
          colour_scale = dataset
                          |> Contex.Dataset.unique_values("Cat")
                          |> Contex.CategoryColourScale.new(["90ee90", "4361ee", "f8961e", "ff0000"])

          cs = %Contex.CategoryColourScale{
            colour_map: %{1 => "1f77b4", 2 => "2ca02c", 3 => "ff7f0e", 4 => "d62728"},
            colour_palette: ["1f77b4", "2ca02c", "ff7f0e", "d62728", "9467bd", "8c564b",
              "e377c2", "7f7f7f", "bcbd22", "17becf"],
            default_colour: nil,
            values: [1, 2, 3, 4]
          }


          plot_content = Contex.GanttChart.new(dataset, category_scale: colour_scale)

          cs_plot = struct(plot_content, category_scale: cs)
          # IO.inspect(Contex.CategoryColourScale.get_default_colour(cs))

          plot = Contex.Plot.new(dataset, Contex.GanttChart, 600, 450, opts)
            |> Contex.Plot.attributes(y_label: "Priorité", x_label: "Dates de début et d'achèvement des tâches")
            Contex.Plot.to_svg(plot)

      _ ->
        # data = Enum.sort_by(this_months, fn(task) -> task.priority_id end)
        pre_data = this_months ++ default_data
        data = Enum.sort_by(pre_data, fn(task) -> task.priority_id end)
        |> Enum.map(fn(task) ->
          ["#{PmLogin.Monitoring.get_priority!(task.priority_id).title}", task.title, date_to_naive(task.date_start), task.achieved_at]
        end)
        |> Enum.reverse

      # IO.puts "io ny data month"
      # IO.inspect data
        dataset = Contex.Dataset.new(data, ["Cat", "Task", "Start", "End"])

        opts =
          [
            default_colour: nil,
            values: ["Faible", "Moyenne", "Importante", "Urgente"],
            mapping:  %{category_col: "Cat", task_col: "Task", start_col: "Start", finish_col: "End"},
            colour_palette: ["ff0000", "f8961e", "4361ee", "008000"],
            colour_map: %{"Faible" => "ff0000", "Moyenne" => "f8961e", "Importante" => "4361ee", "Urgente" => "008000"}
          ]

        # IO.inspect dataset
        colour_scale = dataset
                        |> Contex.Dataset.unique_values("Cat")
                        |> Contex.CategoryColourScale.new(["90ee90", "4361ee", "f8961e", "ff0000"])

        # %Contex.CategoryColourScale{
        #   colour_map: %{1 => "1f77b4", 2 => "ff7f0e", 3 => "2ca02c", 4 => "d62728"},
        #   colour_palette: ["1f77b4", "ff7f0e", "2ca02c", "d62728", "9467bd", "8c564b",
        #     "e377c2", "7f7f7f", "bcbd22", "17becf"],
        #   default_colour: nil,
        #   values: [1, 2, 3, 4]
        # }


        cs = %Contex.CategoryColourScale{
          colour_map: %{1 => "1f77b4", 2 => "2ca02c", 3 => "ff7f0e", 4 => "d62728"},
          colour_palette: ["1f77b4", "2ca02c", "ff7f0e", "d62728", "9467bd", "8c564b",
            "e377c2", "7f7f7f", "bcbd22", "17becf"],
          default_colour: nil,
          values: [1, 2, 3, 4]
        }

        # IO.inspect colour_scale

        plot_content = Contex.GanttChart.new(dataset, category_scale: colour_scale)


        # IO.inspect(plot_content)

        # coloured_plot = struct!(plot_content, category_scale: cs)

        cs_plot = struct(plot_content, category_scale: cs)
        IO.puts "//////"
        # IO.inspect(Contex.CategoryColourScale.get_default_colour(cs))
        # IO.inspect(coloured_plot)
        IO.puts "//////"
        plot = Contex.Plot.new(dataset, Contex.GanttChart, 600, 450, opts)
          |> Contex.Plot.attributes(y_label: "Priorité", x_label: "Dates de début et d'achèvement des tâches")
        # IO.inspect(plot)
          Contex.Plot.to_svg(plot)
        # OLD DATASET
        # data = Enum.map(this_months, fn(task) -> %{category_col: task.priority_id,
        # task_col: task.title, start_col: date_to_datetime(task.date_start), finish_col: naive_to_datetime(task.achieved_at)} end)
        # dataset = Contex.Dataset.new(data)

        # list = Enum.map(this_months, fn(task) -> [task.priority_id, task.title, date_to_datetime(task.date_start), naive_to_datetime(task.achieved_at)] end)

        # list_dataset = Contex.Dataset.new(list)
        # IO.inspect list_dataset
        # # plot_content = Contex.GanttChart.new(dataset, mapping: %{category_col: :category_col, task_col: :task_col, start_col: :start_col, finish_col: :finish_col} )
        # plot_content = Contex.GanttChart.new(list_dataset)


        # plot = Contex.Plot.new(1200, 800, plot_content)
        # output = Contex.Plot.to_svg(plot)
    end

  end

  def test_dataset do
    this_months = Monitoring.list_achieved_tasks_this_month

    case length(this_months) do
      0 -> "Aucune tâche accomplie "
      _ ->
        data = Enum.sort_by(this_months, fn(task) -> task.priority_id end)
          |> Enum.map(fn(task) ->
          [task.priority_id, task.title, date_to_naive(task.date_start), task.achieved_at]
        end)


        # IO.inspect data
        # dataset = Contex.Dataset.new(data, ["Cat", "Task", "Start", "End"])
        # plot_content = Contex.GanttChart.new(dataset)

        # plot = Contex.Plot.new(600, 400, plot_content)
        #   |> Contex.Plot.titles("Sample Gantt Chart", nil)

        #   Contex.Plot.to_svg(plot)

        # list = Enum.map(this_months, fn(task) -> [task.priority_id, task.title, date_to_datetime(task.date_start), naive_to_datetime(task.achieved_at)] end)

        # list_dataset = Contex.Dataset.new(list)
        # IO.inspect list_dataset
        # # plot_content = Contex.GanttChart.new(dataset, mapping: %{category_col: :category_col, task_col: :task_col, start_col: :start_col, finish_col: :finish_col} )
        # plot_content = Contex.GanttChart.new(list_dataset)


        # plot = Contex.Plot.new(1200, 800, plot_content)
        # output = Contex.Plot.to_svg(plot)
    end

  end

  def last_seven_days(contributor_id) do
    data = Monitoring.list_last_seven_days(contributor_id)
    dataset = Contex.Dataset.new(data)
    plot_content = Contex.BarChart.new(dataset)
    plot = Contex.Plot.new(800, 370, plot_content)
    Contex.Plot.to_svg(plot)
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

#   plot_content = BarPlot.new(dataset, 100, 100, orientation)
#   |> BarPlot.defaults()
#   |> BarPlot.type(:stacked)
#   |> BarPlot.padding(2)
#   |> BarPlot.set_val_col_names(Enum.map(1..nseries, fn i -> "Value#{i}" end))
#
# plot = Plot.new(600, 350, plot_content)
#   |> Plot.plot_options(%{legend_setting: :legend_right})
#   |> Plot.titles("Title", nil)
#   |> Plot.plot_options(%{show_y_axis: true})
#
# {:safe, Plot.to_svg(plot)}
#
# image
#
# And for the above
#
# dataset = Reaction.Chart.Dataset.new(data, ["Cat", "Task", "Start", "End"])
# plot_content = GanttChart.new(dataset, 100, 100)
#   |> GanttChart.defaults()
#
# plot = Plot.new(600, 400, plot_content)
#   |> Plot.titles("Test Gantt", nil)
#
# {:safe, Plot.to_svg(plot)}


#CONBOARD

end
