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
            minifyJS: {
                options: {
                    baseUrl: "target/sqlfiddle/ui/sqlfiddle/www/javascript",
                    mainConfigFile: "target/sqlfiddle/ui/sqlfiddle/www/javascript/main.js",
                    include: ["main"],
                    out: "target/sqlfiddle/ui/sqlfiddle/www/javascript/main.js"
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
            copy: {
                files: ['src/main/resources/ui/**/*.js','src/main/resources/script/*.js','src/main/resources/**/*.groovy', 'src/main/resources/ui/**/*.html', 'src/main/resources/conf/*.json', 'src/main/resources/ui/**/*.less', 'src/main/resources/ui/**/*.css'],
                tasks: [ 'sync', 'less', 'requirejs' ]
            }
        }
    });

    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-sync');
    grunt.loadNpmTasks('grunt-contrib-requirejs');
    grunt.loadNpmTasks('grunt-contrib-less');

    grunt.registerTask('default', ['sync', 'less', 'requirejs', 'watch']);

};
