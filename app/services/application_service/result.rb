module ApplicationService
  class Result
    attr_reader :data, :errors

    def initialize(data: nil, errors: [])
      @data = data
      @errors = errors
    end

    def success?
      errors.empty?
    end

    def failure?
      !success?
    end
  end
end
