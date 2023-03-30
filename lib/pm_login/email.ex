defmodule PmLogin.Email do
  import Swoosh.Email

  alias PmLogin.Mailer
  alias PmLogin.{Services, Utilities, Monitoring, Login}

  def send_state_of_client_request(send_to, request_id) do

    request = Services.get_clients_request!(request_id)

    client = Services.get_active_client!(request.active_client_id)

    content =
      cond do
        request.seen and not request.ongoing and not request.done and not request.finished ->
          "
            <p> Bonjour #{client.user.username}, <br/> <p>
            <p> Votre demande ayant l'identifiant N°#{request.uuid}, a été vue par l'administrateur. <br /></p>
            <p> Le #{Utilities.simple_date_format_with_hours request.date_seen} </p>
          "

        request.seen and request.ongoing and not request.done and not request.finished ->
          type = if is_nil(request.task_id) and not is_nil(request.project_id), do: "Projet", else: "Tâche"

          case type do
            "Tâche" ->
              contributor_id = Monitoring.get_task!(request.task_id).contributor_id

              username = Login.get_username(contributor_id)

              "
                <p> Bonjour #{client.user.username}, <br/> <p>
                <p> Votre demande ayant l'identifiant N°#{request.uuid}, a été mise en traitement en tant que Tâche, et sera traité(e) par #{username}. <br /></p>
                <p> Le #{Utilities.simple_date_format_with_hours request.date_ongoing} </p>
              "

            _ ->
              "
                <p> Bonjour #{client.user.username}, <br/> <p>
                <p> Votre demande ayant l'identifiant N°#{request.uuid}, a été mise en traitement en tant que Projet. <br /></p>
                <p> Le #{Utilities.simple_date_format_with_hours request.date_ongoing} </p>
              "
          end

        request.seen and request.ongoing and request.done and not request.finished ->
          "
            <p> Bonjour #{client.user.username}, <br/> <p>
            <p> Votre demande ayant l'identifiant N°#{request.uuid}, a été accomplie. <br /></p>
            <p> Le #{Utilities.simple_date_format_with_hours request.date_done}. </p>
          "

        request.seen and request.ongoing and request.done and request.finished ->
          "
            <p> Bonjour #{client.user.username}, <br/> <p>
            <p> Votre demande ayant l'identifiant N°#{request.uuid}, a été cloturée. <br /></p>
            <p> Le #{Utilities.simple_date_format_with_hours request.date_finished}. </p>
          "

        true ->
          "n'a pas encore été vue"
      end

    new()
    |> from("monitoring@mgbi.mg")
    |> to(send_to)
    |> subject("[Requête N°#{request.uuid}]")
    |> html_body(content)
    |> Mailer.deliver()
  end

  def send_task_in_control_mail(task) do

    attributor = Login.get_user!(task.attributor_id)

    content =
          "
            <p> Bonjour #{attributor.username}, <br/> <p>
            <p> La tâche #{task.title} est en contrôle, veuillez y procéder.<br /></p>
            <p>Informations sur la tâche : </p>
            <table>
              <tr>
                <th>Titre</th>
                <th>Description</th>
                <th>Date de début</th>
                <th>Deadline</th>
              </tr>
              <tr>
                <td>#{task.title}</td>
                <td>#{task.description}</td>
                <td>#{Utilities.simple_date_format task.date_start}</td>
                <td>#{Utilities.simple_date_format task.deadline}</td>
              </tr>
            </table>
          "


    new()
    |> to("andriamihajasambatra@gmail.com")
    |> from("monitoring@mgbi.mg")
    |> subject("Tâche en contrôle")
    # |> text_body("La tâche #{task.title} est en contrôle, veuillez y procéder.")
    |> html_body(content)
    |> Mailer.deliver()
  end

  def send_task_in_deadline_mail(task) do

    attributor = Login.get_user!(task.attributor_id)
    contributor = Login.get_user!(task.contributor_id)

    content =
          "
            <p> Bonjour l'équipe de #{attributor.username}, <br/> <p>
            <p> La date de clôture de la tâche #{task.title} est proche !!!.<br /></p>
            <p>Informations sur la tâche : </p>
            <table>
              <tr>
                <th>Titre</th>
                <th>Description</th>
                <th>Date de début</th>
                <th>Deadline</th>
              </tr>
              <tr>
                <td>#{task.title}</td>
                <td>#{task.description}</td>
                <td>#{Utilities.simple_date_format task.date_start}</td>
                <td>#{Utilities.simple_date_format task.deadline}</td>
              </tr>
            </table>
          "

    new()
    |> to("andriamihajasambatra@gmail.com")
    |> from("monitoring@mgbi.mg")
    |> subject("Deadline")
    #|> text_body("La date de clôture de la tâche #{task.title} est proche !!!")
    |> html_body(content)
    |> Mailer.deliver()
  end


  def mail_test() do
    html_text = "<p>Mail de test envoyé</p>"

    new()
    |> from("monitoring@mgbi.mg")
    |> to("andriamihajasambatra@gmail.com")
    |> subject("[TEST MAIL]")
    |> html_body(html_text)
    |> Mailer.deliver()
  end
end
