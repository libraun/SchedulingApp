class WorkordersController < ApplicationController

    @workorders = Workorder.all


    def new

        @workorder = Workorder.new(workorder_params)
    end

    private
    def workorder_params 

    end
end