defmodule PmLoginWeb.ProjectView do
  alias PmLoginWeb.LiveComponent.{
    SurveyLiveComponent,
    # Task History reason modal
    ReasonTaskHistoryModalLive,
    TaskModalLive,
    PlusModalLive,
    ModifModalLive,
    ModifModalMenu,
    CommentsModalLive,
    CommentsModalMenu,
    SecondaryModalLive,
    # DeleteTaskModal,
    ClientModalRequestLive,
    DetailModalRequestLive,
    ProjectModalLive,
    TaskLiveComponent,
    ProjectLiveComponent,
    UserLiveComponent,
    SidebarLiveComponent,
    ActivityLiveComponent,
    CompletedActivitiesLiveComponent,
    TaskmajorTrueLiveComponent,
    TaskmajorFalseLiveComponent,
    CardTaskmajorFalseLiveComponent,
    CardTaskmajorTrueLiveComponent,
    CardTaskmajorAllLiveComponent,
    VoirModalLive,
    SidebarTrueLiveComponent,
    SidebarFalseLiveComponent,
    Loading
  }

  alias PmLogin.Monitoring
  alias PmLogin.Utilities
  use PmLoginWeb, :view
end
