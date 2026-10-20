module CheckIns
  class Start
    Result = Data.define(:check_in, :errors) do
      def success? = errors.empty?
    end

    def self.call(...) = new(...).call

    def initialize(reservation:, guest_attributes:)
      @reservation = reservation
      @guest = reservation.guest
      @guest_attributes = guest_attributes
    end

    def call
      return Result.new(check_in: @reservation.check_in, errors: {}) if @reservation.check_in
      return failure(base: [ "Check-in is not open for this reservation" ]) unless @reservation.check_in_open?

      @guest.assign_attributes(@guest_attributes)
      return failure(@guest.errors.to_hash) unless @guest.valid?(:check_in)

      check_in = ActiveRecord::Base.transaction do
        @guest.save!(context: :check_in)
        @reservation.create_check_in!
      end
      check_in.enqueue_next_step # after commit so the worker can see the row

      Result.new(check_in:, errors: {})
    rescue ActiveRecord::RecordNotUnique
      Result.new(check_in: @reservation.reload.check_in, errors: {})
    end

    private

    def failure(errors) = Result.new(check_in: nil, errors:)
  end
end
