nap  = require 'nap'
path = require 'path'

module.exports = (env, callback) ->
  preview = 'preview' == env.mode
  roots =
    contents: env.config.contents
    output: env.config.output
    templates: env.config.templates

  # Reading config from wintersmith config object (config.json)
  napCfg = env.config.nap

  # prefix with location of `contents` directory
  for ext of napCfg.assets
    for section of napCfg.assets[ext]
      for index of napCfg.assets[ext][section]
        napCfg.assets[ext][section][index] = if preview then napCfg.assets[ext][section][index] else roots.templates + napCfg.assets[ext][section][index]

  # Setting various `nap` configs
  if preview
    napCfg.appDir    =  path.resolve(env.workDir, roots.templates);
  else
    napCfg.appDir    =  env.workDir
  napCfg.mode      = if preview then 'development' else 'production'
  napCfg.publicDir = if preview then roots.contents else roots.output

  # Instantiate nap!
  nap napCfg
  
  if preview # development
    # Refer to https://github.com/etabits/wintersmith-nap/pull/3#issuecomment-31646159
    assetsRx = new RegExp(path.resolve('/assets/', roots.templates)+'/', 'g')
    createNapWrapper = (ext) ->
      (section) ->
        nap[ext](section).replace(assetsRx, '/')

    env.locals.nap = {}
    env.locals.nap.css = createNapWrapper 'css'
    env.locals.nap.js = createNapWrapper 'js'
    env.locals.nap.jst = createNapWrapper 'jst'

    # we're done
    callback()

  else # production
    env.locals.nap = nap

    env.logger.info('nap.package()...')
    nap.package(callback)
