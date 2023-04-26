defmodule PmLoginWeb.Router do
  use PmLoginWeb, :router

# COMMENTED ROUTES ARE NOT TO BE DELETED BUT JUST NOT USED AT THE TIME

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PmLoginWeb do
    pipe_through :browser

    #contributor route
    get "/logs", ProjectController, :logs
    get "/my_projects", ContributorController, :my_projects
    get "/pointage", ContributorController, :my_records
    get "/my_tasks", ContributorController, :my_tasks


    #Project LiveView
    get "/boards/:id", ProjectController, :board
    get "/recaps", ProjectController, :recaps
    get "/all_tasks", ProjectController, :all_tasks
    get "/requests_center", ProjectController, :requests_center
    #Monitoring context
    # resources "/statuses", StatusController
    get "tasks", ProjectController, :tasks
    get "attributed_tasks", ProjectController, :attributed_tasks
    resources "/projects", ProjectController
    get "/contributors", ProjectController, :contributors
    get "/contributors/:id", ProjectController, :show_contributor
    # resources "/priorities", PriorityController
    resources "/tasks", TaskController, except: [:index, :edit, :show, :new]
    # resources "/comments", CommentController

    #Login context
    resources "/rights", RightController
    resources "/users", UserController
    get "/admin_space", UserController, :admin_space

    #Services context
    resources "/companies", CompanyController
    get "/my_company", CompanyController, :my_company
    get "/services", CompanyController, :services
    # resources "/notifications", NotificationController
    resources "/editors", EditorController
    resources "/softwares", SoftwareController
    resources "/licenses", LicenseController
    resources "/assist_contracts", AssistContractController
    resources "/active_clients", ActiveClientController, except: [:edit, :show]
    resources "/clients_requests", ClientsRequestController
    get "/requests", ClientsRequestController, :requests
    #requests_2 côté admin
    get "/requests_2", ClientsRequestController, :requests_2
    get "/my_requests", ClientsRequestController, :my_requests
    get "/client_tasks", ClientsRequestController, :client_tasks
    get "/client_users", ClientsRequestController, :client_users

    #=== Sondage client ===#
    get "/requests/survey", ClientsRequestController, :survey

    # get ""
    get "/users/:id/edit_profile", UserController, :edit_profile
    get "/users/:id/edit_password", UserController, :edit_password
    get "/list_users", UserController, :list
    put "/profile/:id", UserController, :update_profile
    patch "/profile/:id", UserController, :update_profile
    put "/profile_pass/:id", UserController, :update_password
    patch "/profile_pass/:id", UserController, :update_password
    put "/user/:id", UserController, :archive
    patch "/user/:id", UserController, :archive
    put "/user/restore/:id", UserController, :restore
    patch "/user/restore/:id", UserController, :restore
    get "/", PageController, :index
    post "/auth", AuthController, :auth
    post "/test_auth", AuthController, :test_auth
    get "/signout", AuthController, :sign_out

    #activeclient2
    get "/my_company_2", CompanyController, :my_company_2
    get "/my_requests_2", ClientsRequestController, :my_requests_2
    get "/my_company_requests_2", ClientsRequestController, :my_company_requests_2
    get "/my_projects_clients_2", ActiveClientController, :my_projects_clients_2
    get "/client_tasks_2", ClientsRequestController, :client_tasks_2
    resources "/clients_request", ClientsRequestController, except: [:new, :show]
    resources "/task", TaskController, except: [:new]
  end

  # Other scopes may use custom stacks.
  # scope "/api", PmLoginWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: PmLoginWeb.Telemetry
    end
  end
end
