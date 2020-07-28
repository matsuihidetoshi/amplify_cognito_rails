Rails.application.routes.draw do
  namespace 'api' do
    namespace 'v1' do
      resources :notes
      get 'authenticate', to: 'notes#authenticate'
    end
  end
end
