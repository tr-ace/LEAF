import FormatPreview from "@/components/form_editor_view/FormatPreview";

export default {
    name: 'FormEditingDisplay',
    props: {
        depth: Number,
        formNode: Object,
        index: Number
    },
    components: {
        FormatPreview
    },
    inject: [
        'libsPath',
        'newQuestion',
        'editQuestion',
        'openAdvancedOptionsDialog',
        'openIfThenDialog',
        'listItems',
        'allowedConditionChildFormats',
        'showToolbars',
        'toggleToolbars'
    ],
    mounted() {
        //console.log('form editing area mounted', this.$props);
    },
    computed: {
        isHeaderLocation() {
            let ID = parseInt(this.formNode.indicatorID);
            let item = this.listItems[ID];
            return (item?.parentID === null || item?.newParentID === null);
        },
        sensitiveImg() {
            return this.sensitive ? 
                `<img src="${this.libsPath}dynicons/svg/eye_invisible.svg" style="width: 16px" alt="" class="sensitive-icon"
                    title="This field is sensitive" />` : '';
        },
        conditionalQuestion() {
            return !this.isHeaderLocation && 
                this.formNode.conditions !== null && this.formNode.conditions !== '' & this.formNode.conditions !== 'null';
        },
        conditionsAllowed() {
            return !this.isHeaderLocation && this.allowedConditionChildFormats.includes(this.formNode.format?.toLowerCase());
        },
        indicatorName() {
            const contentRequired = this.required ? `<span class="input-required-sensitive">*&nbsp;Required</span>` : '';
            const contentSensitive = this.sensitive ? `<span class="input-required-sensitive">*&nbsp;Sensitive</span>` : '';

            let name = this.formNode.name.trim() !== '' ?  this.formNode.name.trim() : '[ blank ]';
            name = `${name}${contentRequired}${contentSensitive}  &nbsp;${this.sensitiveImg}`;
            return name;
        },
        printResponseID() {
            return `xhrIndicator_${this.formNode.indicatorID}_${this.formNode.series}`;
        },
        required() {
            return parseInt(this.formNode.required) === 1;
        },
        sensitive() {
            return parseInt(this.formNode.is_sensitive) === 1;
        },
        questionSeparation() {
            return Math.max(24 - this.depth*6, 6) + 'px';
        }
    },
    template:`<div class="printResponse" 
            :class="{'form-header': isHeaderLocation}"
            :style="{marginBottom: questionSeparation}"
            :id="printResponseID">

            <!-- EDITING AREA FOR INDICATOR -->
            <div class="form_editing_area" 
                :class="{'conditional': conditionalQuestion, 'form-header': isHeaderLocation}">

                <!-- TOOLBAR -->
                <div v-show="showToolbars" 
                    :id="'form_editing_toolbar_' + formNode.indicatorID"
                    :class="{'conditional': conditionalQuestion}">
                    <div>
                        <button type="button" @click="editQuestion(parseInt(formNode.indicatorID))"
                            class="btn-general" :title="'edit indicator ' + formNode.indicatorID">Edit</button>
                        <span style="margin-left: 0.5rem; white-space:nowrap; font-weight: normal; color:#404042;">
                            {{formNode?.format}}{{conditionalQuestion ? ', has conditions' : ''}}</span>
                        <span v-if="sensitive" v-html="sensitiveImg" style="margin-left: 0.4rem;"></span>
                    </div>
                    <div>
                        <button v-if="conditionsAllowed" type="button" :id="'edit_conditions_' + formNode.indicatorID" 
                            @click="openIfThenDialog(parseInt(formNode.indicatorID), formNode.name.trim())" 
                            :title="'Edit conditions for ' + formNode.indicatorID" class="icon">
                            <img :src="libsPath + 'dynicons/svg/preferences-system.svg'" style="width: 20px" alt="" />
                        </button>
                        <button type="button" @click="openAdvancedOptionsDialog(parseInt(formNode.indicatorID))"
                            title="Open Advanced Options" class="icon">
                            <img :src="libsPath + 'dynicons/svg/emblem-system.svg'" style="width: 20px" alt="" />
                        </button>
                        <div style="width:26px; display:flex; align-items:center;">
                            <img v-if="formNode.has_code" tabindex="0" title="advanced options are present"
                            style="cursor:pointer; width: 20px" :src="libsPath + 'dynicons/svg/document-properties.svg'" alt="advanced options are present" />
                        </div>
                        <button type="button" class="btn-general add-subquestion" 
                            :title="isHeaderLocation ? 'Add question to section' : 'Add sub-question'"
                            @click="newQuestion(formNode.indicatorID)">
                            + {{isHeaderLocation ? 'Add question to section' : 'Add sub-question'}}
                        </button>
                    </div>
                </div>

                <!-- NAME -->
                <div v-html="indicatorName" @click="toggleToolbars($event)"
                    class="indicator-name-preview" :id="formNode.indicatorID + '_format_label'"></div>
                
                <!-- FORMAT PREVIEW -->
                <div v-if="formNode.format !== ''" class="form_data_entry_preview">
                    <format-preview :indicator="formNode" :key="'FP_' + formNode.indicatorID"></format-preview>
                </div>
            </div>

            <!-- NOTE: RECURSIVE SUBQUESTIONS -->
            <template v-if="formNode.child">
                <form-editing-display v-for="child in formNode.child"
                    :depth="depth + 1"
                    :formNode="child"
                    :key="'FED_' + child.indicatorID">
                </form-editing-display>
            </template>
        </div>`
}