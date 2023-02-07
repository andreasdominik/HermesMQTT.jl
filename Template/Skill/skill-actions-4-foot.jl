    else   # ask returns false
        # do nothing
    end

    Susi.publish_end_session(:end_say)
    return true
end
