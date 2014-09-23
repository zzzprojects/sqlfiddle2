module.exports = function(grunt) {

    grunt.initConfig({
        sync: {
            custom: {
                files: [{
                    cwd     : 'src/main/resources',
                    src     : ['**/*'], 
                    dest    : 'target/sqlfiddle',
                    flatten : false,
                    expand  : true
                }]
            }
        },
        less: {
            production: {
                files: {
                    "target/sqlfiddle/ui/sqlfiddle/www/css/fiddle.css": "src/main/resources/ui/sqlfiddle/www/css/fiddle.less",
                    "target/sqlfiddle/ui/sqlfiddle/www/css/fiddle_responsive.css": "src/main/resources/ui/sqlfiddle/www/css/fiddle_responsive.less",
                    "target/sqlfiddle/ui/sqlfiddle/www/css/fiddle_bootstrap_overrides.css": "src/main/resources/ui/sqlfiddle/www/css/fiddle_bootstrap_overrides.less"
                }
            }
        },
        requirejs: {
            minifyMainJS: {
                options: {
                    baseUrl: "target/sqlfiddle/ui/sqlfiddle/www/javascript",
                    mainConfigFile: "target/sqlfiddle/ui/sqlfiddle/www/javascript/main.js",
                    include: ["almond", "main"],
                    optimize: "uglify2",
                    generateSourceMaps: true,
                    preserveLicenseComments: false,
                    out: "target/sqlfiddle/ui/sqlfiddle/www/javascript/main_min.js"
                }
            },
            minifyOAuthJS: {
                options: {
                    baseUrl: "target/sqlfiddle/ui/sqlfiddle/www/javascript",
                    mainConfigFile: "target/sqlfiddle/ui/sqlfiddle/www/javascript/oauth.js",
                    include: ["almond", "oauth"],
                    optimize: "uglify2",
                    generateSourceMaps: true,
                    preserveLicenseComments: false,
                    out: "target/sqlfiddle/ui/sqlfiddle/www/javascript/oauth_min.js"
                }
            },
            minifyMainCSS: {
                options: {
                    optimizeCss: 'standard',
                    cssIn: 'target/sqlfiddle/ui/sqlfiddle/www/css/styles.css',
                    out: 'target/sqlfiddle/ui/sqlfiddle/www/css/styles_min.css'
                }
            },
            minifyPrintCSS: {
                options: {
                    optimizeCss: 'standard',
                    cssIn: 'target/sqlfiddle/ui/sqlfiddle/www/css/print.css',
                    out: 'target/sqlfiddle/ui/sqlfiddle/www/css/print_min.css'
                }
            }
        },
        watch: {
            copyUIJS: {
                files: ['src/main/resources/ui/**/*.js'],
                tasks: [ 'sync', 'requirejs:minifyMainJS', 'requirejs:minifyOAuthJS' ]
            },
            copyLESS: {
                files: ['src/main/resources/ui/**/*.less', 'src/main/resources/ui/**/*.css'],
                tasks: [ 'sync', 'less', 'requirejs:minifyMainCSS', 'requirejs:minifyPrintCSS' ]
            },
            copyIDM: {
                files: ['src/main/resources/script/*.js','src/main/resources/**/*.groovy', 'src/main/resources/ui/**/*.html', 'src/main/resources/conf/*.json'],
                tasks: [ 'sync' ]
            }

        }
    });

    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-sync');
    grunt.loadNpmTasks('grunt-contrib-requirejs');
    grunt.loadNpmTasks('grunt-contrib-less');

    grunt.registerTask('default', ['sync', 'less', 'requirejs', 'watch']);

};
