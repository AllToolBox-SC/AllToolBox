try:
    import colorama
    print('colorama', colorama.__version__)
except Exception as e:
    print('no colorama', e)
